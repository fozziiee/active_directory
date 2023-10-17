Get-Content -Path "./data/captials.txt" | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_.ToLower()) } | Set-Content -Path "./data/last-names.txt"
