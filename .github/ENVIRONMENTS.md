# GitHub Environments Setup for Docker Workflow

This workflow uses GitHub Environments to control when images are pushed to registries.

## Workflow Behavior

### Build Phase (Always Runs)
The build step runs **immediately without approval** on all branches:
- Builds the Docker image for the target platform
- Uses GitHub Actions cache for efficiency
- Validates the build succeeds

### Push Phase (Approval Controlled)
The push step uses environments to control when images are pushed to registries.

## Required Environments

You need to create two environments in your repository settings:

### 1. `push-main` (Auto-push for main branch)

**Settings:**
- No deployment protection rules
- No required reviewers
- No wait timer

**Usage:** Automatically used when pushing to the `main` branch. Images are pushed to registries without approval (after PR review/merge).

### 2. `push-branch` (Manual approval for other branches)

**Settings:**
- **Required reviewers:** Add one or more reviewers who must approve deployments
- Optional: Add a wait timer if desired
- Optional: Limit to specific branches if needed

**Usage:** Used for all non-main branches. The workflow builds the image immediately, then pauses at the push step and waits for approval before pushing to registries.

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

## Workflow Behavior Examples

### On `main` branch:
1. Build step runs immediately
2. Build completes and caches layers
3. Push step uses `push-main` environment (no approval needed)
4. Pushes to Docker Hub and GHCR automatically
5. Merge job creates multi-arch manifests

### On feature branches:
1. Build step runs immediately
2. Build completes and caches layers
3. Push step uses `push-branch` environment
4. **Workflow pauses and waits for approval**
5. Reviewer approves via GitHub UI
6. Pushes to Docker Hub and GHCR after approval
7. Merge job creates multi-arch manifests

## Benefits

✅ **Fast Feedback:** Build validation happens immediately, no waiting for approval
✅ **Safety:** Manual review required before pushing from feature branches
✅ **Automation:** Automatic pushes from main (after PR review/merge)
✅ **Visibility:** Clear approval workflow in GitHub UI
✅ **Flexibility:** Different rules for different branches
✅ **Efficiency:** Build cache shared between build and push steps
