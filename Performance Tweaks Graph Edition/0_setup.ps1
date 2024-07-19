Connect-MgGraph -Scopes "User.Read.All","Application.Read.All"
connect-entra -Scopes User.Read.All, AuditLog.Read.All

function prompt {
    return  "#PSUGRN >";
}
cls 