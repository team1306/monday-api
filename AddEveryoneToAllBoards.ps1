Import-Module .\Monday -Force

# In Monday, open your profile menu > Developers > API token
# create the variable locally and do not commit
# $token = 'your-monday-api-token' 

$boards = Get-MondayBoards -Token $token
$businessBoards = @(18426967947, 18426967946, 18426968145, 18426968143)

# get all users and remove one
$users = Get-MondayUsers -Token $token | Where-Object Id -ne 110599379
$allUserIds = $users | Select-Object -ExpandProperty id
$memberIds = $users | Where-Object { $_.kind -notin @('guest', 'admin') } | Select-Object -ExpandProperty id
$defaultOwnerIds = $users | Where-Object kind -eq 'admin' | Select-Object -ExpandProperty id
# admin and Brooke Lewis
$businessOwnerIds = @($defaultOwnerIds, 110111072)

foreach ($board in $boards) {
    $owner = $board.owners | Where-Object Id -eq 110597675
    if (!$owner) {
        Write-Warning "Not owner of board [$($board.id)] - $($board.name)"
        continue
    }

    Write-Information "Adding users to board $($board.name)" -InformationAction Continue

    $boardUserIds = $board.subscribers | Select-Object -ExpandProperty id
    $userIds = $allUserids
    if ($board.board_kind -ne 'share') {
        Write-Warning "[$($board.id)] - $($board.name) is not a shared board. guests cannot be added"
        $userIds = $memberIds
    }
    $unsubscribedUserIds = Compare-Object -ReferenceObject $userIds -DifferenceObject $boardUserIds | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
    Add-MondayUsersToBoard -Board $board -UserIds $unsubscribedUserIds -Kind 'subscriber' -Token $token

    $boardOwnerIds = $board.owners | Select-Object -ExpandProperty id
    $ownerIds = ($board.id -in $businessBoards) ? $businessOwnerIds : $defaultOwnerIds
    if ($boardOwnerIds) {
        # arrays are nested, flatten them
        $ownerIds = (($ownerIds + $boardOwnerIds | ForEach-Object { $_ }) | Select-Object -Unique)
    }
    Add-MondayUsersToBoard -Board $board -UserIds ($ownerIds -join ',') -Kind 'owner' -Token $token
}
