<#
.SYNOPSIS
    Discovers codebase artifacts needed for Delete test generation.

.DESCRIPTION
    Searches the LoanIQ codebase for:
    1. Delete integration class: LiqAPIDelete{BusinessObject}Integration.java or LiqAPICancel{BusinessObject}.java
    2. Create integration class: LiqAPICreate{BusinessObject}Integration.java (for bootstrap seed)
    3. Query integration class: LiqAPIQuery{BusinessObject}Integration.java (for verification)
    4. Response class: LiqAPI{BusinessObject}IntegrationAsReturnValue.java
    5. Identifier class: LiqAPI{BusinessObject}Identifier.java or LiqAPIOutstandingTransactionIdentifier.java
    6. GeneralIntegrationMapping enum constants (DELETE_, CREATE_, QUERY_)
    7. Security access symbol (APICommonConstants.SECURITY_ACCESS_SYMBOL_DELETE_*)
    8. Package path
    9. Existing test class (if already present)

.PARAMETER BusinessObject
    Pascal-case business object name (e.g., "UpfrontFee", "Deal", "LoanDrawdown")

.PARAMETER CodebasePath
    Root path of the LoanIQ project (e.g., "C:\Users\asrivas3\git\7740_3\FLIQ-liqjava\LoanIQ")

.EXAMPLE
    .\discover-codebase.ps1 -BusinessObject "UpfrontFee" -CodebasePath "C:\Users\asrivas3\git\7740_3\FLIQ-liqjava\LoanIQ"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$BusinessObject,

    [Parameter(Mandatory=$false)]
    [string]$CodebasePath = "C:\Users\asrivas3\git\7740_3\FLIQ-liqjava\LoanIQ"
)

$upperSnake = ($BusinessObject -creplace '([A-Z])', '_$1').TrimStart('_').ToUpper()

Write-Host "=" * 80
Write-Host "DELETE Test - Codebase Discovery for: $BusinessObject"
Write-Host "Upper snake case: $upperSnake"
Write-Host "Searching in: $CodebasePath"
Write-Host "=" * 80
Write-Host ""

# Step 1: Find Delete Integration Class
Write-Host "STEP 1: Delete Integration Class"
Write-Host "-" * 40
$deleteClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPIDelete${BusinessObject}Integration.java" -ErrorAction SilentlyContinue
if ($deleteClass) {
    Write-Host "  FOUND: $($deleteClass.FullName)"
    $packageLine = Get-Content $deleteClass.FullName | Select-String -Pattern "^package " | Select-Object -First 1
    Write-Host "  Package: $($packageLine.Line)"
    
    # Check for If-Match (setMatchUpdatedTimestamp)
    $hasIfMatch = Get-Content $deleteClass.FullName | Select-String -Pattern "setMatchUpdatedTimestamp|matchUpdatedTimestamp"
    if ($hasIfMatch) {
        Write-Host "  If-Match: YES (requires updateTimeStamp from QUERY)"
    } else {
        Write-Host "  If-Match: NO"
    }
    
    # Check for identifier pattern
    $identifierFields = Get-Content $deleteClass.FullName | Select-String -Pattern "@LiqAPIFieldMapper"
    if ($identifierFields) {
        Write-Host "  Field Mappers:"
        $identifierFields | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
    }
} else {
    Write-Host "  NOT FOUND: LiqAPIDelete${BusinessObject}Integration.java"
    Write-Host "  Searching for Cancel class (Cancel-as-Delete pattern)..."
    $cancelClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPICancel${BusinessObject}*.java" -ErrorAction SilentlyContinue
    if ($cancelClass) {
        Write-Host "  CANCEL CLASS FOUND: $($cancelClass.FullName)"
        Write-Host "  NOTE: This business object uses Cancel-as-Delete pattern (Variant C)"
    } else {
        Write-Host "  WARNING: No delete or cancel class found!"
    }
}
Write-Host ""

# Step 2: Find Create Integration Class (for bootstrap seed)
Write-Host "STEP 2: Create Integration Class (bootstrap seed)"
Write-Host "-" * 40
$createClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPICreate${BusinessObject}Integration.java" -ErrorAction SilentlyContinue
if ($createClass) {
    Write-Host "  FOUND: $($createClass.FullName)"
} else {
    Write-Host "  NOT FOUND: LiqAPICreate${BusinessObject}Integration.java"
    # Look for Update class (ProductGuarantee pattern)
    $updateClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPIUpdate${BusinessObject}Integration.java" -ErrorAction SilentlyContinue
    if ($updateClass) {
        Write-Host "  ALTERNATIVE FOUND (Update/Add): $($updateClass.FullName)"
    }
}
Write-Host ""

# Step 3: Find Query Integration Class
Write-Host "STEP 3: Query Integration Class (verification)"
Write-Host "-" * 40
$queryClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPIQuery${BusinessObject}Integration.java" -ErrorAction SilentlyContinue
if ($queryClass) {
    Write-Host "  FOUND: $($queryClass.FullName)"
} else {
    Write-Host "  NOT FOUND: LiqAPIQuery${BusinessObject}Integration.java"
    Write-Host "  NOTE: Some objects use CREATE response for verification (e.g., ProductGuarantee)"
}
Write-Host ""

# Step 4: Find Response Class
Write-Host "STEP 4: Response (Return Value) Class"
Write-Host "-" * 40
$responseClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPI${BusinessObject}IntegrationAsReturnValue.java" -ErrorAction SilentlyContinue
if ($responseClass) {
    Write-Host "  FOUND: $($responseClass.FullName)"
    $getters = Get-Content $responseClass.FullName | Select-String -Pattern "public .+ get\w+\(\)" | ForEach-Object { $_.Line.Trim() }
    if ($getters) {
        Write-Host "  Getter methods:"
        $getters | ForEach-Object { Write-Host "    $_" }
    }
} else {
    Write-Host "  NOT FOUND: LiqAPI${BusinessObject}IntegrationAsReturnValue.java"
}
Write-Host ""

# Step 5: Find Identifier Class
Write-Host "STEP 5: Identifier Class"
Write-Host "-" * 40
$identifierClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPI${BusinessObject}Identifier.java" -ErrorAction SilentlyContinue
if ($identifierClass) {
    Write-Host "  FOUND (Domain-specific): $($identifierClass.FullName)"
} else {
    $outstandingId = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPIOutstandingTransactionIdentifier.java" -ErrorAction SilentlyContinue
    if ($outstandingId) {
        Write-Host "  Using: LiqAPIOutstandingTransactionIdentifier (outstanding transaction pattern)"
        Write-Host "  Path: $($outstandingId.FullName)"
    }
    $ownerIdClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPIOwnerIdentifier.java" -ErrorAction SilentlyContinue
    if ($ownerIdClass) {
        Write-Host "  Also available: LiqAPIOwnerIdentifier (owner pattern)"
        Write-Host "  Path: $($ownerIdClass.FullName)"
    }
}
Write-Host ""

# Step 6: Find GeneralIntegrationMapping Enum Constants
Write-Host "STEP 6: GeneralIntegrationMapping Enum Constants"
Write-Host "-" * 40
$mappingFile = Get-ChildItem -Path $CodebasePath -Recurse -Filter "GeneralIntegrationMapping.java" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($mappingFile) {
    # Search for DELETE constants
    $deleteEnums = Get-Content $mappingFile.FullName | Select-String -Pattern "DELETE.*${upperSnake}|DELETE.*$($BusinessObject.ToUpper())" -CaseSensitive
    if ($deleteEnums) {
        Write-Host "  DELETE enum constants:"
        $deleteEnums | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
    } else {
        Write-Host "  WARNING: No DELETE enum constants found for $upperSnake"
    }
    
    # Search for CREATE constants
    $createEnums = Get-Content $mappingFile.FullName | Select-String -Pattern "CREATE.*${upperSnake}|CREATE.*$($BusinessObject.ToUpper())" -CaseSensitive
    if ($createEnums) {
        Write-Host "  CREATE enum constants:"
        $createEnums | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
    }
    
    # Search for QUERY constants
    $queryEnums = Get-Content $mappingFile.FullName | Select-String -Pattern "QUERY.*${upperSnake}|QUERY.*$($BusinessObject.ToUpper())" -CaseSensitive
    if ($queryEnums) {
        Write-Host "  QUERY enum constants:"
        $queryEnums | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
    }
} else {
    Write-Host "  WARNING: GeneralIntegrationMapping.java not found!"
}
Write-Host ""

# Step 7: Find Existing Test Class
Write-Host "STEP 7: Existing Test Class"
Write-Host "-" * 40
$existingTest = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPIDelete${BusinessObject}IntegrationTest.java" -ErrorAction SilentlyContinue
if ($existingTest) {
    Write-Host "  FOUND: $($existingTest.FullName)"
    $testMethods = Get-Content $existingTest.FullName | Select-String -Pattern "@Test" | Measure-Object
    Write-Host "  Existing test methods: $($testMethods.Count)"
} else {
    # Check for Cancel test class
    $cancelTest = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPICancel${BusinessObject}IntegrationTest.java" -ErrorAction SilentlyContinue
    if ($cancelTest) {
        Write-Host "  FOUND (Cancel): $($cancelTest.FullName)"
    } else {
        Write-Host "  NOT FOUND: Test class does not exist yet (will be created)"
    }
}
Write-Host ""

# Step 8: Check temp folder for generated files
Write-Host "STEP 8: Temp Generated Files"
Write-Host "-" * 40
$tempPath = "C:\Users\asrivas3\git\7740_3\FLIQ-liqjava\IntegrationAPITool\artifacts\temp_generated_class"
if (Test-Path $tempPath) {
    $tempFiles = Get-ChildItem -Path $tempPath -Filter "*Delete*${BusinessObject}*" -ErrorAction SilentlyContinue
    if ($tempFiles) {
        Write-Host "  Temp files found:"
        $tempFiles | ForEach-Object { Write-Host "    $($_.FullName)" }
    } else {
        Write-Host "  No delete-related temp files for $BusinessObject"
    }
    
    # Also check for JSON payloads
    $jsonFiles = Get-ChildItem -Path $tempPath -Filter "*${BusinessObject}*.json" -ErrorAction SilentlyContinue
    if ($jsonFiles) {
        Write-Host "  JSON payloads found:"
        $jsonFiles | ForEach-Object { Write-Host "    $($_.FullName)" }
    }
} else {
    Write-Host "  Temp folder not found at: $tempPath"
}
Write-Host ""

# Step 9: Security Access Symbol
Write-Host "STEP 9: Security Access Symbol"
Write-Host "-" * 40
$constantsFile = Get-ChildItem -Path $CodebasePath -Recurse -Filter "APICommonConstants.java" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($constantsFile) {
    $secSymbol = Get-Content $constantsFile.FullName | Select-String -Pattern "DELETE.*${upperSnake}|DELETE.*$($BusinessObject.ToUpper())"
    if ($secSymbol) {
        Write-Host "  Security symbol:"
        $secSymbol | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
    } else {
        Write-Host "  No explicit constant found. Symbol likely: Delete${BusinessObject}Integration"
    }
} else {
    Write-Host "  APICommonConstants.java not found"
}
Write-Host ""
Write-Host "=" * 80
Write-Host "Discovery complete."
Write-Host "=" * 80
