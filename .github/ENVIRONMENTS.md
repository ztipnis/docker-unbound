# GitHub Environments Setup for Docker Workflow

This workflow uses GitHub Environments to control when images are pushed to registries.

## Required Environments

You need to create two environments in your repository settings:

### 1. `push-main` (Auto-push for main branch)

**Settings:**
- No deployment protection rules
- No required reviewers
- No wait timer

**Usage:** Automatically used when pushing to the `main` branch. The build and push happens immediately without approval.

### 2. `push-branch` (Manual approval for other branches)

**Settings:**
- **Required reviewers:** Add one or more reviewers who must approve deployments
- Optional: Add a wait timer if desired

**Usage:** Used for all non-main branches. The workflow waits for approval before building and pushing to registries.

## How to Set Up Environments

1. Go to your repository on GitHub
2. Click **Settings** → **Environments**
3. Click **New environment**
4. Create `push-main`:
   - Name: `push-main`
   - Click **Configure environment**
   - Leave all protection rules disabled
   - Save
5. Create `push-branch`:
   - Name: `push-branch`
   - Click **Configure environment**
   - Enable **Required reviewers**
   - Add yourself and/or team members as reviewers
   - Save

## Workflow Behavior

### On `main` branch:
1. Uses `push-main` environment (no approval needed)
2. Builds and pushes to Docker Hub and GHCR automatically
3. Merge job creates multi-arch manifests

### On other branches:
1. Uses `push-branch` environment (approval required)
2. **Workflow pauses and waits for approval**
3. After approval: builds and pushes to registries
4. Merge job creates multi-arch manifests

## Benefits

✅ **Safety:** Manual review required before pushing from feature branches
✅ **Automation:** Automatic pushes from main (after PR review/merge)
✅ **Efficiency:** Single build per architecture with optimized caching
✅ **Visibility:** Clear approval workflow in GitHub UI
✅ **Flexibility:** Different rules for different branches
