param([string]$Godot='godot')
$ErrorActionPreference='Stop'
Set-Location -LiteralPath $PSScriptRoot
New-Item -ItemType Directory -Force '.godot/verification','builds' | Out-Null
${engine}=$Godot
$results=@()
$graphical=@('verify_intro.gd','verify_customer_pose.gd','verify_customer_dialogue.gd','verify_hospital_visits.gd','verify_hud.gd','verify_pause_menu.gd','verify_scrubbing_audio.gd','verify_interaction_input.gd')
foreach($test in Get-ChildItem -Filter 'verify_*.gd' | Sort-Object Name){
 $testLog=Join-Path '.godot/verification' ('v060-'+$test.BaseName+'.log')
 $arguments=@('--path','.', '--script',$test.Name,'--max-fps','120','--quit-after','7200')
 if($test.Name -notin $graphical){$arguments=@('--headless')+$arguments}
 if($test.Name -eq 'verify_scare_showcase.gd'){$arguments+=@('--','--scare-test')}
 & $engine @arguments *> $testLog
 $code=$LASTEXITCODE
 $content=Get-Content $testLog -Raw
 $ok=$code -eq 0 -and $content.Contains('PASS:') -and $content -notmatch 'SCRIPT ERROR|Parse Error|Assertion failed'
 $results+=[PSCustomObject]@{name=$test.Name;passed=$ok;exit_code=$code}
 $results | ConvertTo-Json | Set-Content '.godot/verification/release-check-results.json'
 Write-Output "$($test.Name): $ok"
 if(-not $ok){Select-String -Path $testLog -Pattern 'ERROR:|Assertion|SCRIPT ERROR|PASS:' | Select-Object -First 7 | ForEach-Object {$_.Line}}
}
Write-Output "RESULT: $(($results | Where-Object passed).Count)/$($results.Count) passed"
if($results.passed -contains $false){exit 1}
