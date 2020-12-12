# GameJam

## Updating the codebase:

* Solution 1: no conflicts with new-online version

```bash
git fetch origin
git status
```

will report something like:

```bash
Your branch is behind 'origin/master' by 1 commit, and can be fast-forwarded.
```

Then get the latest version

```bash
git pull
```

 * Solution 2: conflicts with new-online version

```bash
git fetch origin
git status
```

will report something like:

```bash
error: Your local changes to the following files would be overwritten by merge:
    file_name
Please, commit your changes or stash them before you can merge.
Aborting
```

Commit your local changes

```bash
git add .
git commit -m ‘Commit msg’
```

Try to get the changes (will fail)

```bash
git pull
```

will report something like:

```bash
Pull is not possible because you have unmerged files.
Please, fix them up in the work tree, and then use 'git add/rm <file>'
as appropriate to mark resolution, or use 'git commit -a'.
```

Open the conflict file and fix the conflict. Then:

```bash
git add .
git commit -m ‘Fix conflicts’
git pull
```

will report something like:

```bash
Already up-to-date.
```

Source: [StackOverflow](http://stackoverflow.com/a/26464271/485397)