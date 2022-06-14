IF %1.==. (git commit -a -m "temp") ELSE (git commit -a -m %1)
git push