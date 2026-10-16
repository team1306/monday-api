Import-Module .\Monday -Force

# In Monday, open your profile menu > Developers > API token
# create the variable locally and do not commit
# $token = 'your-monday-api-token' 

$boards = Get-MondayBoards -Token $token
$businessBoards = @(18426967947, 18426967946, 18426968145, 18426968143)

# get all users and remove excluded ids
$excludedIds = @(110599379)
$users = Get-MondayUsers -Token $token | Where-Object Id -notin $excludedIds
# array of only ids
$allUserIds = $users | Select-Object -ExpandProperty id
# members only (no guest or admin users)
$memberIds = $users | Where-Object { $_.kind -notin @('guest', 'admin') } | Select-Object -ExpandProperty id
# all admins will be owners
$defaultOwnerIds = @($users | Where-Object kind -eq 'admin' | Select-Object -ExpandProperty id)
# admin and Brooke Lewis
$brookeId = $users | Where-Object name -eq 'Brooke Lewis' | Select-Object -ExpandProperty id
$businessOwnerIds = $defaultOwnerIds + $brookeId

$myId = Get-MyId -Token $token

foreach ($board in $boards) {
    # need to be an owner to assign users
    $owner = $board.owners | Where-Object Id -eq $myId
    if (!$owner) {
        Write-Warning "Not owner of board [$($board.id)] - $($board.name)"
        continue
    }

    Write-Information "Adding users to board $($board.name)" -InformationAction Continue

    $boardOwnerIds = @($board.owners | Select-Object -ExpandProperty id)
    # include owners so existing owners aren't added again as subscribers
    $boardUserIds = @($board.subscribers | Select-Object -ExpandProperty id) + $boardOwnerIds
    $userIds = $allUserids
    if ($board.board_kind -ne 'share') {
        Write-Warning "[$($board.id)] - $($board.name) is not a shared board. guests cannot be added"
        $userIds = $memberIds
    }
    $unsubscribedUserIds = Compare-Object -ReferenceObject $userIds -DifferenceObject $boardUserIds | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
    Add-MondayUsersToBoard -Board $board -UserIds $unsubscribedUserIds -Kind 'subscriber' -Token $token

    $ownerIds = ($board.id -in $businessBoards) ? $businessOwnerIds : $defaultOwnerIds
    $unsubscribedOwnerIds = Compare-Object -ReferenceObject ($ownerIds | Select-Object -Unique) -DifferenceObject $boardOwnerIds | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
    Add-MondayUsersToBoard -Board $board -UserIds $unsubscribedOwnerIds -Kind 'owner' -Token $token
}
