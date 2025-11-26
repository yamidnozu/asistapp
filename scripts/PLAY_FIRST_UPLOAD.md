Play Console: Manual first upload + grant Play API access (CI)

Summary
-------
If the Play Console app has not been created or the service account has not been granted access, CI preflight will show HTTP 404. This file contains the steps to do the first manual upload and grant API access to the service account so CI can continue publishing builds.

Steps to perform first upload and grant service account access
--------------------------------------------------------------
1. Download the AAB from the CI run artifacts:
   - Open the Actions run that built the AAB (the 'build' job).
   - In the build job, go to 'Artifacts' and download the `release-artifacts` zip or AAB.

2. Login to Play Console with the correct developer account
   - URL: https://play.google.com/console
   - Choose the correct developer account if you have multiple organizations.

3. Create a new app (if not already present)
   - In Play Console, click 'All apps' -> 'Create app'
   - Fill in *App name*, language, and choose app type (App or Game) and target.
   - Complete setup to create the app. You don't need to complete all metadata now; just create the basic app for the first AAB upload.

4. Create an internal test track and upload the AAB
   - Go to 'Release' -> 'Testing' -> 'Internal testing' → Create release.
   - Upload the AAB you downloaded from the CI artifact.
   - Fill in any necessary release notes and artifacts and click 'Review release' -> 'Start rollout to internal testing'.
   - This initial upload will initialize Play's backend for the given package name.

5. Grant the CI service account API access and permissions
   - In Play Console > Settings > API access (https://play.google.com/console/developers/api-access):
     - Link your Google Cloud project if not already linked.
     - Click 'Create new service account' OR 'Grant access' to the existing service account.
     - If you created a new service account, make sure it's the same email that CI uses (e.g., `asistapp-play-svc@...`) and you've uploaded the JSON key to the GitHub secret `PLAY_STORE_SERVICE_ACCOUNT`.
     - Grant 'Release Manager' or Admin role for this service account (or 'Release Manager' + full app access). Optionally set 'All apps'.

6. If the service account is already in the GCP project, ensure it's listed under Play Console API users:
   - On 'Settings' → 'API access', add the service account to the Play Console users with the appropriate role(s). This is a must—CI will not be able to publish otherwise.

7. Wait 1–2 minutes and re-run your CI workflow
   - Re-run the release workflow or push a new commit to retrigger the release-android workflow.
   - If the preflight now returns 200/201, CI will proceed to upload.

Notes and common edge-cases
--------------------------
- If the app is present but belongs to another developer account, the Play Console API will still return 404 to the incorrect service account. Verify you're using the correct developer account and package name.
- If you created the app manually but the package name in the AAB is different, verify the applicationId in `android/app/build.gradle` matches the package you created.
- For teams: the person with Play Console owner permissions should perform steps 3–6.

Troubleshooting
---------------
- If you get 403 after the above steps, it means the service account needs additional permissions. Add it under 'Users & permissions' in Play Console and give 'Admin' or 'Release Manager' roles.
- If you still see 404, double-check the package name and that the service account is added to 'API access' in Play Console.

Automated follow-up (optional):
- If you want us to add a short workflow to attempt a test upload during CI and create an issue if it fails, I can implement that to make problems easier to follow.

