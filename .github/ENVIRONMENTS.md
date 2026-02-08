# GitHub Environments Setup for Docker Workflow

This workflow uses GitHub Environments to control when images are pushed to registries.

## Required Environments

You need to create two environments in your repository settings:

### 1. `production-auto` (Auto-approval for main branch)

**Settings:**
- No deployment protection rules
- No required reviewers
- No wait timer

**Usage:** Automatically used when pushing to the `main` branch. Images are built and pushed without approval.

### 2. `production-manual` (Manual approval for other branches)

**Settings:**
- **Required reviewers:** Add one or more reviewers who must approve deployments
- Optional: Add a wait timer if desired
- Optional: Limit to specific branches if needed

**Usage:** Used for all non-main branches. The workflow will pause at the build step and wait for approval before pushing images to registries.

## How to Set Up Environments

1. Go to your repository on GitHub
2. Click **Settings** → **Environments**
3. Click **New environment**
4. Create `production-auto`:
   - Name: `production-auto`
   - Click **Configure environment**
   - Leave all protection rules disabled
   - Save
5. Create `production-manual`:
   - Name: `production-manual`
   - Click **Configure environment**
   - Enable **Required reviewers**
   - Add yourself and/or team members as reviewers
   - Save

## Workflow Behavior

### On `main` branch:
1. Build job runs
2. Uses `production-auto` environment (no approval needed)
3. Pushes to Docker Hub and GHCR automatically
4. Merge job creates multi-arch manifests

### On other branches:
1. Build job runs
2. Uses `production-manual` environment
3. **Workflow pauses and waits for approval**
4. Reviewer approves via GitHub UI
5. Pushes to Docker Hub and GHCR after approval
6. Merge job creates multi-arch manifests

## Benefits

✅ **Safety:** Manual review before pushing from feature branches
✅ **Automation:** Automatic pushes from main (after PR review)
✅ **Visibility:** Clear approval workflow in GitHub UI
✅ **Flexibility:** Different rules for different branches
