<#
.SYNOPSIS
    Discovers codebase artifacts needed for Create test generation.

.DESCRIPTION
    Searches the LoanIQ codebase for:
    1. Integration (request) class: LiqAPICreate{BusinessObject}Integration.java
    2. Response class: LiqAPI{BusinessObject}IntegrationAsReturnValue.java
    3. GeneralIntegrationMapping enum constants matching the business object
    4. Security access symbol (APICommonConstants.SECURITY_ACCESS_SYMBOL_*)
    5. Package path
    6. Superclass and imports

.PARAMETER BusinessObject
    Pascal-case business object name (e.g., "UserProfile", "Deal", "Facility")

.PARAMETER CodebasePath
    Root path of the LoanIQ project (e.g., "C:\Users\asrivas3\git\7740_3\FLIQ-liqjava\LoanIQ")

.EXAMPLE
    .\discover-codebase.ps1 -BusinessObject "UserProfile" -CodebasePath "C:\Users\asrivas3\git\7740_3\FLIQ-liqjava\LoanIQ"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$BusinessObject,

    [Parameter(Mandatory=$false)]
    [string]$CodebasePath = "C:\Users\asrivas3\git\7740_3\FLIQ-liqjava\LoanIQ"
)

$upperSnake = ($BusinessObject -creplace '([A-Z])', '_$1').TrimStart('_').ToUpper()

Write-Host "=" * 80
Write-Host "Codebase Discovery for: $BusinessObject"
Write-Host "Upper snake case: $upperSnake"
Write-Host "Searching in: $CodebasePath"
Write-Host "=" * 80
Write-Host ""

# Step 1: Find Integration (Request) Class
Write-Host "STEP 1: Integration (Request) Class"
Write-Host "-" * 40
$createClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPICreate${BusinessObject}Integration.java" -ErrorAction SilentlyContinue
if ($createClass) {
    Write-Host "  FOUND: $($createClass.FullName)"
    $packageLine = Get-Content $createClass.FullName | Select-String -Pattern "^package " | Select-Object -First 1
    Write-Host "  Package: $($packageLine.Line)"
} else {
    Write-Host "  NOT FOUND: LiqAPICreate${BusinessObject}Integration.java"
    Write-Host "  Searching for alternative (Update class for Add operations)..."
    $updateClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPIUpdate${BusinessObject}Integration.java" -ErrorAction SilentlyContinue
    if ($updateClass) {
        Write-Host "  ALTERNATIVE FOUND: $($updateClass.FullName)"
    } else {
        Write-Host "  WARNING: No integration class found!"
    }
}
Write-Host ""

# Step 2: Find Response Class
Write-Host "STEP 2: Response (Return Value) Class"
Write-Host "-" * 40
$responseClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPI${BusinessObject}IntegrationAsReturnValue.java" -ErrorAction SilentlyContinue
if ($responseClass) {
    Write-Host "  FOUND: $($responseClass.FullName)"
    # Extract getter methods
    $getters = Get-Content $responseClass.FullName | Select-String -Pattern "public .+ get\w+\(\)" | ForEach-Object { $_.Line.Trim() }
    if ($getters) {
        Write-Host "  Getter methods:"
        $getters | ForEach-Object { Write-Host "    $_" }
    }
} else {
    Write-Host "  NOT FOUND: LiqAPI${BusinessObject}IntegrationAsReturnValue.java"
}
Write-Host ""

# Step 3: Find GeneralIntegrationMapping Enum Constants
Write-Host "STEP 3: GeneralIntegrationMapping Enum Constants"
Write-Host "-" * 40
$mappingFile = Get-ChildItem -Path $CodebasePath -Recurse -Filter "GeneralIntegrationMapping.java" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($mappingFile) {
    $enumConstants = Get-Content $mappingFile.FullName | Select-String -Pattern "CREATE_${upperSnake}|CREATE_${BusinessObject.ToUpper()}" -CaseSensitive
    if ($enumConstants) {
        Write-Host "  Matching enum constants:"
        $enumConstants | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
    } else {
        # Try broader search
        $enumConstants = Get-Content $mappingFile.FullName | Select-String -Pattern "$($BusinessObject.ToUpper())" -CaseSensitive
        if ($enumConstants) {
            Write-Host "  Broader search results:"
            $enumConstants | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
        } else {
            Write-Host "  WARNING: No matching enum constants found for $upperSnake"
        }
    }
} else {
    Write-Host "  WARNING: GeneralIntegrationMapping.java not found!"
}
Write-Host ""

# Step 4: Find Security Access Symbol
Write-Host "STEP 4: Security Access Symbol"
Write-Host "-" * 40
$constantsFile = Get-ChildItem -Path $CodebasePath -Recurse -Filter "APICommonConstants.java" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($constantsFile) {
    $symbolLines = Get-Content $constantsFile.FullName | Select-String -Pattern "SECURITY_ACCESS_SYMBOL.*$($BusinessObject.ToUpper())|SECURITY_ACCESS_SYMBOL.*CREATE.*$($BusinessObject.ToUpper())"
    if ($symbolLines) {
        Write-Host "  Security symbol constants:"
        $symbolLines | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
    } else {
        # Try case-insensitive broader search
        $symbolLines = Get-Content $constantsFile.FullName | Select-String -Pattern "SECURITY_ACCESS_SYMBOL" | Select-String -Pattern "$BusinessObject" -CaseSensitive:$false
        if ($symbolLines) {
            Write-Host "  Broader search:"
            $symbolLines | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
        } else {
            Write-Host "  WARNING: No security symbol found. Check integration class for securityAccessSymbol() method."
        }
    }
} else {
    Write-Host "  WARNING: APICommonConstants.java not found!"
}
Write-Host ""

# Step 5: Find Superclass
Write-Host "STEP 5: Superclass"
Write-Host "-" * 40
$superClass = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPICreate${BusinessObject}.java" -ErrorAction SilentlyContinue
if ($superClass) {
    Write-Host "  FOUND: $($superClass.FullName)"
    $superPackage = Get-Content $superClass.FullName | Select-String -Pattern "^package " | Select-Object -First 1
    Write-Host "  Package: $($superPackage.Line)"
} else {
    Write-Host "  NOT FOUND: LiqAPICreate${BusinessObject}.java (may not have a separate superclass)"
}
Write-Host ""

# Step 6: Existing Test Class
Write-Host "STEP 6: Existing Test Class"
Write-Host "-" * 40
$existingTest = Get-ChildItem -Path $CodebasePath -Recurse -Filter "LiqAPICreate${BusinessObject}IntegrationTest.java" -ErrorAction SilentlyContinue
if ($existingTest) {
    Write-Host "  EXISTING TEST FOUND: $($existingTest.FullName)"
    $lineCount = (Get-Content $existingTest.FullName).Count
    Write-Host "  Lines: $lineCount"
    Write-Host "  NOTE: Test class already exists. New generation will replace/enhance it."
} else {
    Write-Host "  No existing test class found. Will create new."
}
Write-Host ""

# Summary
Write-Host "=" * 80
Write-Host "DISCOVERY SUMMARY"
Write-Host "=" * 80
Write-Host "  Business Object:     $BusinessObject"
Write-Host "  Integration Class:   LiqAPICreate${BusinessObject}Integration"
Write-Host "  Response Class:      LiqAPI${BusinessObject}IntegrationAsReturnValue"
Write-Host "  Enum Prefix:         CREATE_${upperSnake}_*"
Write-Host "  Test Class:          LiqAPICreate${BusinessObject}IntegrationTest"
Write-Host ""
