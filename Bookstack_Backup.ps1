#Backup Bookstack Website
New-item -ItemType "Directory" -Path C:\Users\user\OneDrive\Bookstack\.\$((Get-Date).ToString('dd-MM-yyyy'))
#Variables - Secure Password created already
$User = "root"
$File = "C:\Users\user\.ssh\sshpw"
$KeyFile = "C:\Users\user\.ssh\exportopenssh"
$MyCredential = New-Object -TypeName System.Management.Automation.PSCredential `
-ArgumentList $User, (Get-Content $File | ConvertTo-SecureString)

#Created the SSH session and starts to backup the files
function SSHSessuion {
New-SSHSession -ComputerName ip -KeyFile $KeyFile -Port 22 -Credential $MyCredential -Verbose -AcceptKey
$SSHIndex = Get-SSHSession | Select-Object SessionId
Invoke-SSHCommand -SessionId $SShIndex.SessionId -Command "sudo mysqldump -u root bookstack > bookstack.backup.sql" -Verbose
Invoke-SSHCommand -SessionId $SSHIndex.SessionId -Command "sudo tar cvf bookstack_files_backup.tar.gz /var/www/bookstack" -Verbose
}


#Creates the SFTP Session, downloads the files and copy to my onedrive account
function SFTPSession {
New-SFTPSession -ComputerName ip -Credential $MyCredential -Port 22 -KeyFile $KeyFile
$SFTPIndex = Get-SFTPSession | Select-Object SessionId
Get-SFTPFile -SessionId $SFTPIndex.SessionId -RemoteFile bookstack.backup.sql -LocalPath C:\Users\user\OneDrive\Bookstack\.\$((Get-Date).ToString('dd-MM-yyyy')) -Verbose
Get-SFTPFile -SessionId $SFTPIndex.SessionId -RemoteFile bookstack_files_backup.tar.gz -LocalPath C:\Users\user\OneDrive\Bookstack\.\$((Get-Date).ToString('dd-MM-yyyy')) -Verbose
Remove-SFTPSession -SessionId $SFTPIndex.SessionId
}

SSHSessuion
SFTPSession

#Removes the backups from the Linux Server and SSH Session
$SSHIndex = Get-SSHSession | Select-Object SessionId
Invoke-SSHCommand -SessionId $SSHIndex.SessionId -Command "rm bookstack*" -Verbose
Remove-SSHSession -SessionId $SSHIndex.SessionId

#Remove the older Bookstack backups (Set to 2 days before)
Get-ChildItem -Path "C:\Users\user\OneDrive\Bookstack" -Directory -recurse| where {$_.CreationTime -le $(get-date).Adddays(-2)} | Remove-Item -recurse -force
