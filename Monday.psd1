@{
    # The manifest itself has no root module; Monday.psm1 is loaded as a nested module.
    RootModule        = ''
    NestedModules     = @('Monday.psm1')

    ModuleVersion     = '1.0.0'
    GUID              = '442c3482-0cfe-465b-bd77-bd8d2268d3b6'
    Author            = ''
    Description       = 'PowerShell helpers for working with the Monday.com API.'

    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        'Get-MondayUsers'
        'Get-MondayBoards'
        'Add-MondayUsersToBoard'
        'Invoke-MondayApi'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
