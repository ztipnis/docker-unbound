# GitHub Environments Setup for Docker Workflow

This workflow uses GitHub Environments to control when manifest tags are created.

## Workflow Design

The workflow is designed to provide immediate PR validation while controlling when tagged releases happen:

1. **Build Job**: Runs immediately (no approval) - builds and pushes by digest
2. **Merge Job**: Requires approval (via environment) - creates manifest lists with tags

This approach ensures PRs are validated immediately while still requiring approval for tagged releases.

## Required Environments

You need to create two environments in your repository settings:

### 1. `push-main` (Auto-tag for main branch)

**Settings:**
- No deployment protection rules
- No required reviewers
- No wait timer

**Usage:** Automatically used when pushing to the `main` branch. Tags are created immediately after the build completes.

### 2. `push-branch` (Manual approval for other branches)

**Settings:**
- **Required reviewers:** Add one or more reviewers who must approve deployments
- Optional: Add a wait timer if desired

**Usage:** Used for all non-main branches. The workflow builds and pushes by digest immediately (for PR validation), then waits for approval before creating tagged manifest lists.

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
1. **Build job** runs immediately:
   - Builds Docker images for amd64 and arm64
   - Pushes by digest to Docker Hub and GHCR (no tags yet)
2. **Merge job** uses `push-main` environment (no approval needed):
   - Creates multi-arch manifest lists
   - Applies tags: branch, semver, version, latest

### On other branches:
1. **Build job** runs immediately:
   - Builds Docker images for amd64 and arm64
   - Pushes by digest to Docker Hub and GHCR (no tags yet)
   - ✅ **PR is validated immediately**
2. **Merge job** uses `push-branch` environment (approval required):
   - **⏸️ Workflow pauses and waits for approval**
   - After approval: creates multi-arch manifest lists with tags

## Benefits

✅ **Immediate PR Validation:** Builds happen instantly for all branches
✅ **Approval Control:** Only tagging requires approval, not building
✅ **Efficient:** Single build per architecture using official Docker actions
✅ **Safe:** Manual review required before creating tagged releases from branches
✅ **Automated:** Auto-tag from main after PR merge
✅ **Flexible:** Different rules for different branches

