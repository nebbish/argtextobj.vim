# Add various existing forks as remotes:

    git remote add f_twschum https://github.com/twschum/argtextobj.vim
    git remote add f_sasdf https://github.com/sasdf/argtextobj.vim
    git remote add f_pneff https://github.com/pneff/argtextobj.vim
    git remote add f_iahmad1337 https://github.com/iahmad1337/argtextobj.vim
    git remote add f_inkarkat https://github.com/inkarkat/argtextobj.vim

## Get the refs:

    git fetch --all

# Now build branch merge commands:

    echo & git branch --list --remotes | perl -ne 'print "git squash-branch $1\n" if m{^\s*(f_.+?)\s*$}m'

