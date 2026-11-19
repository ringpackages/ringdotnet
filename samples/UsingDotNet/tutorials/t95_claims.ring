# identities and claims - ClaimsIdentity, ClaimsPrincipal, roles, claim types and a simple permission check
load "dotnet.ring"
using {
	"System"
	"System.Security.Claims"
}

func main
	# A claim is a statement about a user: a type and a value ("Role" = "Admin", "Email" = "ann@example.com").
	# An identity is a list of claims from one source; a principal holds identities. ASP.NET uses these classes for every login.
	oIdentity = dnNew("ClaimsIdentity",[ :authenticationType = "Password" ])
	oIdentity.AddClaim(dnNew("Claim",[ :type = "Name", :value = "Ann" ]))
	oIdentity.AddClaim(dnNew("Claim",[ :type = "Email", :value = "ann@example.com" ]))
	oIdentity.AddClaim(dnNew("Claim",[ :type = "Role", :value = "Editor" ]))
	oIdentity.AddClaim(dnNew("Claim",[ :type = "Role", :value = "Reviewer" ]))
	oPrincipal = dnNew("ClaimsPrincipal",[ :identity = oIdentity ])

	? "1. authentication type: " + oIdentity.AuthenticationType + ", authenticated: " + oIdentity.IsAuthenticated
	? "   claims: " + len(oIdentity.Claims.toList())
	for oClaim in oIdentity.Claims.toList()
		? "      " + oClaim.Type + " = " + oClaim.Value
	next

	# 2. Find a claim: FindFirst gives the first claim of a type, FindAll all of them, HasClaim answers yes or no
	? nl + "2. email: " + oPrincipal.FindFirst("Email").Value
	cRoles = ""
	for oRole in oPrincipal.FindAll("Role").toList()
		cRoles += oRole.Value + " "
	next
	? "   roles: " + cRoles
	? "   has claim Role=Editor: " + oPrincipal.HasClaim([ :type = "Role", :value = "Editor" ]) + ", has claim Role=Admin: " + oPrincipal.HasClaim([ :type = "Role", :value = "Admin" ])

	# 3. Roles: IsInRole looks at the claims of the role type. A new identity must say which claim type is the role.
	oRoleIdentity = dnNew("ClaimsIdentity",[ :authenticationType = "Password", :nameType = "Name", :roleType = "Role" ])
	oRoleIdentity.AddClaim(dnNew("Claim",[ :type = "Name", :value = "Ann" ]))
	oRoleIdentity.AddClaim(dnNew("Claim",[ :type = "Role", :value = "Editor" ]))
	oRolePrincipal = dnNew("ClaimsPrincipal",[ :identity = oRoleIdentity ])
	? nl + "3. name: " + oRoleIdentity.Name
	? "   is Editor: " + oRolePrincipal.IsInRole("Editor") + ", is Admin: " + oRolePrincipal.IsInRole("Admin")

	# 4. A permission check in Ring: the rules are data (what a role may do), the claims say who the user is
	aRules = [ :Editor = ["read","write"], :Reviewer = ["read","comment"], :Admin = ["read","write","delete"] ]
	? nl + "4. permissions of the user:"
	for cAction in ["read","write","comment","delete"]
		? "   " + cAction + ": " + mayDo(oPrincipal,aRules,cAction)
	next

# True when one of the roles of the principal allows the action
func mayDo oPrincipal, aRules, cAction
	for oRole in oPrincipal.FindAll("Role").toList()
		aAllowed = aRules[lower(oRole.Value)]
		if not islist(aAllowed) loop ok
		if find(aAllowed,cAction) > 0
			return True
		ok
	next
	return False
