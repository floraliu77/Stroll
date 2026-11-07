# Stroll: how we work in Git

The short version: **one branch per task, a pull request to merge it, and nobody pushes
straight to `main`.**

## The rules

1. **`main` always works.** It's the version anyone can download and build. Don't work on it
   directly.
2. **One branch per task**, started from the latest `main`. Name it `yourname/task`, for
   example `mara/journal-screen` or `flora/poi-data-file`.
3. **Keep tasks small**, a few days at most. "Build the Journal screen" is a good size;
   "build the companion app" is too big.
4. **Open a pull request when the task is done**, and merge it soon. Don't keep branches
   around for weeks: the longer they live, the harder they are to merge.
5. **Reviews:** Flora reviews anything that changes app code, because she can build and run
   it on the iPhone and watch. Docs and design changes can be reviewed by anyone.
6. **Avoid editing the same files as someone else at the same time.** Agree on who's working
   on what before you start.

## Step by step

You can do all of this in the free **GitHub Desktop** app instead of typing commands: it has
buttons for each step (*Fetch origin*, *New branch*, *Commit*, *Push*, *Create pull request*).

**1. Get the latest `main`**

```bash
git checkout main
git pull
```

**2. Create your branch**

```bash
git checkout -b yourname/task-name
```

**3. Save your work as you go**

```bash
git add -A
git commit -m "Short description of what changed"
```

**4. Upload your branch**

```bash
git push -u origin yourname/task-name
```

**5. Open a pull request.** Go to https://github.com/floraliu77/Stroll. GitHub shows a
*Compare & pull request* button for your branch. Describe what you changed and how to check
it, and ask a teammate to review.

**6. After it's merged**, delete the branch on GitHub (there's a button on the pull request),
then go back to step 1 for your next task.

## If your branch is behind `main`

If teammates merged work while you were on your branch, bring it in before you open your
pull request:

```bash
git checkout main
git pull
git checkout yourname/task-name
git merge main
```

If Git reports a **conflict**, it marks the clashing parts of the files. Fix them, then
`git add -A` and `git commit`. If you're unsure, ask Flora before going further.

## Things specific to Stroll

- **The Xcode project isn't in Git.** `Stroll.xcodeproj` is generated from `project.yml`.
  After pulling, or after adding or removing files, run `xcodegen` in the project folder.
  Change project settings in `project.yml`, not in Xcode's settings screens, or they'll be
  lost the next time someone runs `xcodegen`.
- **Read `docs/round1-plan.md` before starting.** It's the team's source of truth for what
  we're building.
- **Never commit passwords or API keys**, for example the ElevenLabs key. Keep them in
  environment variables.

## If you're working with Claude

Start the chat by telling Claude:

> Read docs/round1-plan.md and docs/git-workflow.md. Work on a new branch named
> yourname/task, and open a pull request instead of pushing to main.
