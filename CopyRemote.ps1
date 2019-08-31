#run this script to download selected files and directory trees from renote sever to windows directory.
$loc=Get-Location
bash -c "rsync -avz --include '*/' --include={'*.xml','OUTCAR'} --exclude='*' username@server:/directory/to/download /Destination/directory"
#use above command without 'bash -c' in linux.
Set-Location $loc
