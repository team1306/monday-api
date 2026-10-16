<#
.SYNOPSIS
    Gets the users in the monday.com account
.DESCRIPTION
    Returns up to 1000 users with their id, name, email, created_at, and kind
    (member, admin, guest, or view_only).
.PARAMETER Token
    monday.com API token
.EXAMPLE
    Get-MondayUsers -Token $token | Where-Object kind -eq 'admin'
#>
function Get-MondayUsers() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Token)

    $query = @"
query {
  users(limit: 1000) {
    id
    name
    email
    created_at
    kind
  }
}
"@

    $users = Invoke-MondayApi -Query $query -Token $Token
    return $users.users
}

<#
.SYNOPSIS
    Gets the active, non-private boards in the monday.com account
.DESCRIPTION
    Queries the first 50 boards and returns only active boards of type 'board'
    (sub-item boards and documents are excluded) whose board_kind is not 'private'.
    Each board includes id, name, type, state, board_kind, owners, and subscribers.
.PARAMETER Token
    monday.com API token
.EXAMPLE
    Get-MondayBoards -Token $token | Select-Object id, name, board_kind
#>
function Get-MondayBoards() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Token)

    $query = @"
query {
  boards(limit: 50) {
    id
    name
    type
    state
    board_kind
    owners {
      id
      name
    }
    subscribers {
      id
      name
    }
  }
}
"@

    $boards = Invoke-MondayApi -Query $query -Token $Token
    return $boards.boards | Where-Object { $_.type -eq 'board' -and $_.state -eq 'active' -and $_.board_kind -ne 'private' }
}

<#
.SYNOPSIS
    Adds users to a monday.com board as subscribers or owners
.DESCRIPTION
    Runs the add_users_to_board mutation and writes the names of the added users to
    the information stream. Does nothing if UserIds is empty.
.PARAMETER UserIds
    Ids of the users to add
.PARAMETER Kind
    Role to give the users on the board: 'subscriber' or 'owner'
.PARAMETER Board
    Board object from Get-MondayBoards (uses its id and name)
.PARAMETER Token
    monday.com API token
.EXAMPLE
    Add-MondayUsersToBoard -Board $board -UserIds @(123, 456) -Kind 'subscriber' -Token $token
#>
function Add-MondayUsersToBoard() {
    [CmdletBinding()]
    param(
        [array]$UserIds,
        $Kind,
        $Board,
        $Token)

    if ($UserIds.Count -eq 0) {
        Write-Information "All users assigned to board $($Board.name)" -InformationAction Continue
        return
    }

    $userMutation = @"
mutation {
  add_users_to_board(
    board_id: $($Board.id)
    user_ids: [$($UserIds -join ',')]
    kind: $($Kind)) { name }
}
"@

    $users = Invoke-MondayApi -Query $userMutation -Token $Token
    Write-Information "Added [$($users.add_users_to_board.name -join ', ')] to board $($Board.name) as $($Kind)" -InformationAction Continue
}


<#
.SYNOPSIS
    Sends a GraphQL query or mutation to the monday.com API
.DESCRIPTION
    Posts to https://api.monday.com/v2/ using API version 2026-07 and returns the
    response's data object. If the API returns errors, writes them as a
    non-terminating error (including column details for column value errors)
    and returns nothing.
.PARAMETER Query
    GraphQL query or mutation text
.PARAMETER Token
    monday.com API token
.EXAMPLE
    $data = Invoke-MondayApi -Query 'query { me { id name } }' -Token $token
    $data.me
#>
function Invoke-MondayApi {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Query')]
        [string] $Query,
        [Parameter(Mandatory)]
        [string] $Token)

    $headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = $Token
        'API-Version' = '2026-07'
    }

    $graphQuery = @{
        "query"= $Query
    }

    try {
        $response = Invoke-WebRequest -Uri 'https://api.monday.com/v2/' -Method Post -Headers $headers -Body ($graphQuery | ConvertTo-Json)
        $content = $response.Content | ConvertFrom-Json -Depth 100
        if ($content.errors) {
            $errors = " $($content.errors.message)"
            $errorData = $content.errors.extensions.error_data
            if ($errorData.column_id) {
                $errors += "`n [$($errorData.column_id) | $($errorData.column_type)] $($errorData.column_name): $($errorData.column_value)"
            }
        } else {
            $content.data
        }
    } catch {
        $errors = ($_ | ConvertFrom-Json).errors.message
    }

    if ($errors) {
        Write-Error (($errors -is [array]) ? $errors -join "`r`n" : $errors)
    }
}
