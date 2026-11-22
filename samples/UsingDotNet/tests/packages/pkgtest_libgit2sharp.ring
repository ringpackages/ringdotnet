# LibGit2Sharp: a Git repository made in a folder (a native library), files staged and committed, history, branches, tags and the status of the working folder
load "pkg.ring"
pkgUse("libgit2sharp",[["LibGit2Sharp","0.32.0"]],[["LibGit2Sharp.dll",["LibGit2Sharp"]]])
pkgImport("libgit2sharp","LibGit2Sharp.dll","LibGit2Sharp")
dnImport("System")
dnImport("System.IO")

cFolder = currentdir() + "/.cache/gitrepo"
pkgRemoveDir(cFolder)
pkgMakeDir(cFolder)

# make a repository: Init gives the path of the .git folder
cGit = dnStatic("LibGit2Sharp.Repository","Init",[cFolder])
dnAssert("a repository was made",right(substr(cGit,"\","/"),5),".git/")
oRepository = dnNew("LibGit2Sharp.Repository",[cFolder])
dnAssert("a new repository has no commits",oRepository.Head.Tip.isNull(),1)
dnAssert("the repository is not bare",oRepository.Info.IsBare,0)

# a file, staged, and a commit with an author
write(cFolder + "/readme.txt","hello from Ring")
dnRequest("call",[dnType("LibGit2Sharp.Commands"),"Stage",oRepository,"readme.txt"])
oAuthor = dnNew("LibGit2Sharp.Signature",["Ring Author","author@example.org",dnStatic("System.DateTimeOffset","Now",[])])
oOptions = new CommitOptions()
oCommit = oRepository.Commit("first commit",oAuthor,oAuthor,oOptions)
dnAssert("the message of a commit",oCommit.MessageShort,"first commit")
dnAssert("the author of a commit",oCommit.Author.Name,"Ring Author")
dnAssert("an id of 40 hex characters",len(oCommit.Sha),40)
dnAssert("the head is the commit",oRepository.Head.Tip.Sha,oCommit.Sha)

# a second commit with a changed and a new file
write(cFolder + "/readme.txt","hello again")
write(cFolder + "/notes.txt","some notes")
dnRequest("call",[dnType("LibGit2Sharp.Commands"),"Stage",oRepository,"*"])
oSecond = oRepository.Commit("second commit",oAuthor,oAuthor,oOptions)
aLog = oRepository.Commits.toList()
dnAssert("two commits in the history, newest first",len(aLog),2)
dnAssert("the newest message",aLog[1].MessageShort,"second commit")
dnAssert("the parent of the second commit",oSecond.Parents.toList()[1].Sha,oCommit.Sha)

# the files of a commit are in its tree
dnAssert("the tree has two files",len(oSecond.Tree.toList()),2)

# a branch and a tag
oBranch = oRepository.Branches.Add([ :name = "feature", :commit = oSecond ])
dnAssert("a branch was made",oBranch.FriendlyName,"feature")
dnAssert("two branches",len(oRepository.Branches.toList()),2)
oRepository.Tags.Add([ :name = "v1.0", :target = oSecond ])
dnAssert("a tag",oRepository.Tags.toList()[1].FriendlyName,"v1.0")

# the status of the working folder: a changed file and a new file
write(cFolder + "/notes.txt","changed notes")
write(cFolder + "/new.txt","new")
oStatus = oRepository.RetrieveStatus(new StatusOptions())
dnAssert("the working folder is dirty",oStatus.IsDirty,1)
dnAssert("one new file",len(oStatus.Untracked.toList()),1)
dnAssert("one modified file",len(oStatus.Modified.toList()),1)

oRepository.Dispose()
pkgRemoveDir(cFolder)
dnTestSummary()
