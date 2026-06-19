function Convert-BFToSixSevenLang ([string]$brainfuckCode) {
    if ([string]::IsNullOrEmpty($brainfuckCode)) { return "" }

    $bf = $brainfuckCode -replace '[^><+\-.,\[\]]', ''

    $mapping = @{
        '>' = '6'
        '<' = '7'
        '+' = '67'
        '-' = '6767'
        '.' = '676767'
        ',' = 'sixseven'
        '[' = 'six'
        ']' = 'seven'
    }

    $sixsevenArray = @()
    foreach ($char in $bf.ToCharArray()) {
        $sixsevenArray += $mapping[[string]$char]
    }

    return $sixsevenArray -join '.'
}

function Convert-SixSevenLangToBF ([string]$sixsevenCode) {
    if ([string]::IsNullOrEmpty($sixsevenCode)) { return "" }

    $instructions = @($sixsevenCode -split '\.' | Where-Object { $_ -ne '' })

    $bfArray = @()
    foreach ($instruction in $instructions) {
        switch ($instruction) {
            '6' { $bfArray += '>' }
            '7' { $bfArray += '<' }
            '67' { $bfArray += '+' }
            '6767' { $bfArray += '-' }
            '676767' { $bfArray += '.' }
            'sixseven' { $bfArray += ',' }
            'six' { $bfArray += '[' }
            'seven' { $bfArray += ']' }
            default { }
        }
    }

    return $bfArray -join ''
}

function Invoke-Interpreter ([string]$rawCode) {
    if ([string]::IsNullOrEmpty($rawCode)) {
        return
    }
    $code = @($rawCode.ToCharArray() | Where-Object {
        ("><+-.,[]".ToCharArray()) -contains $_
    })

    $memory = New-Object byte[] 30000
    $ptr = 0
    $ip = 0

    while ($ip -lt $code.Count) {
        switch ($code[$ip]) {
            '>' {
                $ptr = ($ptr + 1) % 30000
            }
            '<' {
                if ($ptr -eq 0) {
                    $ptr = 29999
                } else {
                    $ptr--
                }
            }
            '+' {
                $memory[$ptr] = ($memory[$ptr] + 1) % 256
            }
            '-' {
                if ($memory[$ptr] -eq 0) {
                    $memory[$ptr] = 255
                } else {
                    $memory[$ptr]--
                }
            }
            '.' {
                Write-Host ([char]$memory[$ptr]) -NoNewline
            }
            ',' { 
                $key = [Console]::ReadKey($true)
                $memory[$ptr] = [byte]$key.KeyChar
            }
            '[' {
                if ($memory[$ptr] -eq 0) {
                    $depth = 1

                    while ($depth -gt 0) {
                        $ip++

                        if ($ip -ge $code.Count) {
                            break
                        }

                        if ($code[$ip] -eq '[') {
                            $depth++
                        } elseif ($code[$ip] -eq ']') {
                            $depth--
                        }
                    }
                }
            }
            ']' {
                if ($memory[$ptr] -ne 0) {
                    $depth = 1

                    while ($depth -gt 0) {
                        $ip--
                        if ($ip -lt 0) {
                            break
                        }

                        if ($code[$ip] -eq ']') {
                            $depth++
                        } elseif ($code[$ip] -eq '[') {
                            $depth--
                        }
                    }
                }
            }
        }

        $ip++
    }
}

function Convert-TextToBF ([string]$text) {
    if ([string]::IsNullOrEmpty($text)) {
        return ""
    }

    $bf = ""
    $currentVal = 0

    foreach ($char in $text.ToCharArray()) {
        $targetVal = [int][char]$char
        $diff = $targetVal - $currentVal

        if ([Math]::Abs($diff) -gt 15) {
            $bf += "[-]" 
            $currentVal = 0
            $factor = [Math]::Floor([Math]::Sqrt($targetVal))
            if ($factor -lt 2) {
                $factor = 2
            }
            $count = [Math]::Floor($targetVal / $factor)
            $remainder = $targetVal % $factor

            $bf += (">" + ("+" * $factor) + "[<" + ("+" * $count) + ">-]<" + ("+" * $remainder))
        } else {
            if ($diff -gt 0) {
                $bf += ("+" * $diff)
            } elseif ($diff -lt 0) {
                $bf += ("-" * [Math]::Abs($diff))
            }
        }

        $bf += "."
        $currentVal = $targetVal
    }
    return $bf
}

Write-Host "╔═══════════════════════════════════════════════════╗"
Write-Host "║         ~ SixSevenLanguage Interpreter ~          ║"
Write-Host "║ Options:                                          ║"
Write-Host "║ 1. Interpret SixSevenLang Code                    ║"
Write-Host "║ 2. Convert Text to SixSevenLang                   ║"
Write-Host "║ 3. Exit                                           ║"
Write-Host "╚═══════════════════════════════════════════════════╝"

Write-Host ">>> " -NoNewline
$choice = Read-Host

Write-Host "`n"

switch ($choice) {
    "1" {
        $loadFromFile = Read-Host "Load from file? (y/n)"

        if ($loadFromFile -eq 'y') {
            $filePath = Read-Host "Enter the file path"

            if (Test-Path $filePath) {
                $67Code = Get-Content -Path $filePath -Raw
            } else {
                Write-Error "$filePath not found."
                exit
            }
        } else {
            $67Code = Read-Host "Paste your SixSevenLang code"
        }

        Invoke-Interpreter (Convert-SixSevenLangToBF $67Code)

        Write-Host "`nExecution completed." -ForegroundColor Green
    }
    "2" {
        $loadTextFromFile = Read-Host "Load text from file? (y/n)"

        if ($loadTextFromFile -eq 'y') {
            $filePath = Read-Host "Enter the file path"
            if (Test-Path $filePath) {
                $textToConvert = Get-Content -Path $filePath -Raw
            } else {
                Write-Error "$filePath not found."
                exit
            }
        } else {
            $textToConvert = Read-Host "Enter the text to convert"
        }

        $generated67Lang = Convert-BFToSixSevenLang (Convert-TextToBF $textToConvert)

        $writeToFile = Read-Host "Write to file? (y/n)"
        if ($writeToFile -eq 'y') {
            $outputFile = Read-Host "Enter output file path"
            Set-Content -Path $outputFile -Value $generated67Lang -Encoding utf8NoBOM -NoNewline
            Write-Host -ForegroundColor Green "SixSevenLang code written to $outputFile"
        } else {
            Write-Host "Generated Code:`n" -ForegroundColor Green
            Write-Host $generated67Lang
        }
    }
    "3" {
        exit
    }
}