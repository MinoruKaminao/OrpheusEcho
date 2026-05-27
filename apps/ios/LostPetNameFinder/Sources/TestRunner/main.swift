import Foundation
import LostPetNameFinder

@main
@MainActor
struct TestRunner {
    static func main() async {
        print("=== Starting API Client Connection Test ===")
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let docPath = paths.first {
            let fileURL = docPath.appendingPathComponent("orpheus_local_data.json")
            try? FileManager.default.removeItem(at: fileURL)
            print("Removed local persistence at \(fileURL.path)")
        }
        
        let client = APIClient(baseURL: URL(string: "http://127.0.0.1:8001/api/v1")!)
        
        // 1. Create Session
        print("\n--- 1. Creating Exploration Session ---")
        await client.createSession(species: .dog, tempId: "DOG-TEST-999", notes: "Test notes via Swift runner")
        
        let session = client.currentSession
        if let session = session {
            print("Session created successfully!")
            print("Session ID: \(session.session_id)")
            print("Species: \(session.species)")
            print("Notes: \(session.notes ?? "nil")")
            print("Status: \(session.status)")
        } else {
            print("FAILED: No current session set.")
            exit(1)
        }
        
        // 2. Fetch Candidates
        print("\n--- 2. Fetching Candidates ---")
        await client.fetchCandidates(species: .dog)
        let candidates = client.candidates
        print("Candidates fetched: \(candidates.count)")
        for c in candidates {
            print(" - \(c.name) (ID: \(c.candidate_id))")
        }
        if candidates.isEmpty {
            print("FAILED: Candidates list is empty.")
            exit(1)
        }
        
        // 3. Record Trial
        print("\n--- 3. Recording Trial ---")
        let firstCandidate = candidates[0]
        print("Recording trial for: \(firstCandidate.name)")
        await client.recordTrial(candidateId: firstCandidate.candidate_id, name: firstCandidate.name, reaction: "reaction_yes")
        
        let trials = client.trials
        print("Trials count: \(trials.count)")
        if let lastTrial = trials.last {
            print("Recorded Trial ID: \(lastTrial.trial_id)")
            print("Candidate Name: \(lastTrial.variant_text)")
            print("Reaction: \(lastTrial.manual_flag ?? "nil")")
        } else {
            print("FAILED: No trials recorded.")
            exit(1)
        }
        
        let ranked = client.rankedCandidates
        print("Ranked Candidates (after trial):")
        for r in ranked {
            print(" - \(r.name): score \(r.score), uncertain \(r.uncertainty_flag), confidence: \(r.confidence ?? "nil"), explanation: \(r.explanation ?? "nil")")
        }
        if ranked.isEmpty {
            print("FAILED: No ranked candidates returned.")
            exit(1)
        }
        for r in ranked {
            if r.confidence == nil {
                print("FAILED: Ranked candidate is missing confidence in Phase 3.")
                exit(1)
            }
            if r.explanation == nil || r.explanation!.isEmpty {
                print("FAILED: Ranked candidate is missing explanation in Phase 3.")
                exit(1)
            }
        }
        
        // 4. Refine Candidates
        print("\n--- 4. Refining Candidates ---")
        await client.refineCandidates()
        let refined = client.rankedCandidates
        print("Refined Candidates:")
        for r in refined {
            print(" - \(r.name): score \(r.score), uncertain \(r.uncertainty_flag), confidence: \(r.confidence ?? "nil"), explanation: \(r.explanation ?? "nil")")
        }
        for r in refined {
            if r.confidence == nil {
                print("FAILED: Refined candidate is missing confidence in Phase 3.")
                exit(1)
            }
            if r.explanation == nil || r.explanation!.isEmpty {
                print("FAILED: Refined candidate is missing explanation in Phase 3.")
                exit(1)
            }
        }
        
        // 5. Close Session
        print("\n--- 5. Closing Session ---")
        await client.closeSession()
        let closedSession = client.currentSession
        if let status = closedSession?.status {
            print("Session status after close: \(status)")
            if status == .closed {
                print("Session closed successfully.")
            } else {
                print("FAILED: Session status is not closed.")
                exit(1)
            }
        } else {
            print("FAILED: Current session is nil.")
            exit(1)
        }
        
        // --- Scenario 2: Offline Exploration & Sync Verification ---
        print("\n=== Scenario 2: Offline Exploration & Sync ===")
        print("Toggling offline mode ON...")
        client.isOffline = true
        
        print("\nCreating offline session...")
        await client.createSession(species: .cat, tempId: "CAT-OFFLINE-999", notes: "Captured during offline mode test")
        
        guard let offlineSession = client.currentSession else {
            print("FAILED: No offline session created.")
            exit(1)
        }
        
        print("Offline Session Created: \(offlineSession.session_id)")
        if !offlineSession.session_id.contains("offline") {
            print("FAILED: Offline session ID does not contain 'offline'.")
            exit(1)
        }
        
        print("Fetching offline candidates...")
        await client.fetchCandidates(species: .cat)
        
        print("Recording trial while offline...")
        await client.recordTrial(candidateId: "cand_003", name: "ルナ", reaction: "reaction_yes")
        
        print("Closing session while offline...")
        await client.closeSession()
        if client.currentSession?.status != .closed {
            print("FAILED: Offline session was not marked closed locally.")
            exit(1)
        }
        
        print("Sync queues status before online sync:")
        print(" - Pending Sessions: \(client.pendingSessions.count)")
        print(" - Pending Trials: \(client.pendingTrials.count)")
        print(" - Pending Features: \(client.pendingFeatures.count)")
        
        if client.pendingSessions.isEmpty || client.pendingTrials.isEmpty {
            print("FAILED: Sync queues are empty before sync.")
            exit(1)
        }
        
        print("\nToggling offline mode OFF & performing synchronization...")
        await client.syncOfflineData()
        
        print("Sync queues status after sync:")
        print(" - Pending Sessions: \(client.pendingSessions.count)")
        print(" - Pending Trials: \(client.pendingTrials.count)")
        print(" - Pending Features: \(client.pendingFeatures.count)")
        
        if !client.pendingSessions.isEmpty || !client.pendingTrials.isEmpty || !client.pendingFeatures.isEmpty {
            print("FAILED: Sync queues are not empty after sync.")
            exit(1)
        }
        
        let syncedSessionId = client.currentSession?.session_id ?? ""
        print("Synced Online Session ID: \(syncedSessionId)")
        if syncedSessionId.contains("offline") {
            print("FAILED: Session ID was not remapped to online ID.")
            exit(1)
        }
        
        // --- Scenario 3: Report Export Validation ---
        print("\n=== Scenario 3: Report Export ===")
        for format in ["json", "csv", "pdf"] {
            print("Requesting export for format: \(format)")
            do {
                let exportRes = try await client.exportReport(sessionId: syncedSessionId, format: format)
                print(" - Export status: \(exportRes.status)")
                print(" - Export download URL: \(exportRes.download_url)")
                
                // HTTP GETで実際にファイルがダウンロード可能かチェック
                let fileURL = URL(string: exportRes.download_url)!
                var request = URLRequest(url: fileURL)
                request.httpMethod = "GET"
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print(" - SUCCESS: Exported file is downloadable! (Size: \(data.count) bytes)")
                } else {
                    print(" - FAILED: Download returned non-200 status code.")
                    exit(1)
                }
            } catch {
                print(" - FAILED: Export request error: \(error.localizedDescription)")
                exit(1)
            }
        }
        
        // --- Scenario 4: Known Animal Registration, Image, and Training Session Validation ---
        print("\n=== Scenario 4: Known Animal & Training Session ===")
        
        print("\n1. Registering Known Animal...")
        await client.registerKnownAnimal(
            species: .cat,
            trueName: "タマ",
            aliases: ["タマちゃん", "タマたん"],
            sex: "female",
            ageRange: "adult",
            breed: "mixed",
            coatColor: "calico",
            consent: "agreed"
        )
        
        guard let lastAnimal = client.knownAnimals.last else {
            print("FAILED: No known animals registered.")
            exit(1)
        }
        print("Registered Known Animal ID: \(lastAnimal.known_animal_id)")
        print("True Name: \(lastAnimal.true_name)")
        
        print("\n2. Registering Photo Metadata...")
        let imageId = await client.uploadAnimalImage(
            knownAnimalId: lastAnimal.known_animal_id,
            fileName: "tama_profile.jpg",
            contentType: "image/jpeg"
        )
        if let imageId = imageId {
            print("Successfully registered image metadata. Image ID: \(imageId)")
        } else {
            print("FAILED: Image metadata registration failed.")
            exit(1)
        }
        
        print("\n3. Creating Training Session...")
        await client.createTrainingSession(
            knownAnimalId: lastAnimal.known_animal_id,
            speaker: "owner",
            environment: "indoor",
            purpose: "positive_negative_collection"
        )
        guard let trSession = client.currentTrainingSession else {
            print("FAILED: No training session active.")
            exit(1)
        }
        print("Training Session Created ID: \(trSession.training_session_id)")
        
        print("\n4. Recording Positive/Negative Training Trials...")
        await client.recordTrainingTrial(
            calledName: "タマ",
            isTrueName: true,
            isAlias: false,
            modulation: "normal",
            source: "owner_live_voice",
            reaction: "reaction_yes"
        )
        await client.recordTrainingTrial(
            calledName: "タマちゃん",
            isTrueName: true,
            isAlias: true,
            modulation: "nickname",
            source: "owner_live_voice",
            reaction: "reaction_yes"
        )
        await client.recordTrainingTrial(
            calledName: "チョコ",
            isTrueName: false,
            isAlias: false,
            modulation: "normal",
            source: "owner_live_voice",
            reaction: "reaction_no"
        )
        
        print("Trials recorded count: \(client.trainingTrials.count)")
        if client.trainingTrials.count != 3 {
            print("FAILED: Training trials count mismatch.")
            exit(1)
        }
        
        print("\n5. Completing Training Session...")
        await client.completeTrainingSession()
        if client.currentTrainingSession?.status != "completed" {
            print("FAILED: Training session status is not completed.")
            exit(1)
        }
        print("Training session completed successfully.")
        
        // --- Scenario 4.2: Offline Known Animal Flow & Sync ---
        print("\n=== Scenario 4.2: Offline Known Animal & Sync ===")
        print("Toggling offline mode ON...")
        client.isOffline = true
        
        print("\nRegistering Known Animal while offline...")
        await client.registerKnownAnimal(
            species: .dog,
            trueName: "コタロウ",
            aliases: ["コタちゃん"],
            sex: "male",
            ageRange: "young",
            breed: "shiba",
            coatColor: "red",
            consent: "agreed"
        )
        guard let offlineAnimal = client.knownAnimals.last, offlineAnimal.known_animal_id.contains("offline") else {
            print("FAILED: Offline known animal not generated.")
            exit(1)
        }
        print("Offline Known Animal Created ID: \(offlineAnimal.known_animal_id)")
        
        print("\nCreating training session while offline...")
        await client.createTrainingSession(
            knownAnimalId: offlineAnimal.known_animal_id,
            speaker: "owner",
            environment: "outdoor",
            purpose: "positive_negative_collection"
        )
        guard let offlineTrSession = client.currentTrainingSession, offlineTrSession.training_session_id.contains("offline") else {
            print("FAILED: Offline training session not created.")
            exit(1)
        }
        print("Offline Training Session Created ID: \(offlineTrSession.training_session_id)")
        
        print("\nRecording trials while offline...")
        await client.recordTrainingTrial(
            calledName: "コタロウ",
            isTrueName: true,
            isAlias: false,
            modulation: "normal",
            source: "owner_live_voice",
            reaction: "reaction_yes"
        )
        await client.recordTrainingTrial(
            calledName: "ポチ",
            isTrueName: false,
            isAlias: false,
            modulation: "normal",
            source: "owner_live_voice",
            reaction: "reaction_no"
        )
        
        print("\nCompleting training session while offline...")
        await client.completeTrainingSession()
        if client.currentTrainingSession?.status != "completed" {
            print("FAILED: Offline training session not completed locally.")
            exit(1)
        }
        
        print("\nSync queues status before online sync:")
        print(" - Pending Known Animals: \(client.pendingKnownAnimals.count)")
        print(" - Pending Training Sessions: \(client.pendingTrainingSessions.count)")
        print(" - Pending Training Trials: \(client.pendingTrainingTrials.count)")
        
        if client.pendingKnownAnimals.isEmpty || client.pendingTrainingSessions.isEmpty || client.pendingTrainingTrials.isEmpty {
            print("FAILED: Phase 4 sync queues are empty before sync.")
            exit(1)
        }
        
        print("\nToggling offline mode OFF & performing synchronization...")
        await client.syncOfflineData()
        
        print("Sync queues status after sync:")
        print(" - Pending Known Animals: \(client.pendingKnownAnimals.count)")
        print(" - Pending Training Sessions: \(client.pendingTrainingSessions.count)")
        print(" - Pending Training Trials: \(client.pendingTrainingTrials.count)")
        
        if !client.pendingKnownAnimals.isEmpty || !client.pendingTrainingSessions.isEmpty || !client.pendingTrainingTrials.isEmpty {
            print("FAILED: Phase 4 sync queues are not empty after sync.")
            exit(1)
        }
        print("SUCCESS: Phase 4 offline queue sync completed!")
        
        // --- Scenario 5: Batch Training & Model Distribution ---
        print("\n=== Scenario 5: Batch Training & Model Distribution ===")
        
        print("Initial model version: \(client.currentModelVersion)")
        if client.currentModelVersion != "1.0.0" {
            print("FAILED: Default model version should be 1.0.0")
            exit(1)
        }
        
        print("\n1. Running training data export...")
        guard let exportJobId = await client.exportTrainingData(
            sessionIds: [syncedSessionId],
            trainingSessionIds: [trSession.training_session_id]
        ) else {
            print("FAILED: Training data export failed")
            exit(1)
        }
        print("Export Job created ID: \(exportJobId)")
        
        print("\n2. Spawning training sync batch job...")
        guard let syncJobId = await client.syncTrainingData(exportJobId: exportJobId) else {
            print("FAILED: Sync training job failed")
            exit(1)
        }
        print("Sync Learning Job created ID: \(syncJobId)")
        
        print("\n3. Waiting for learning job completion...")
        var jobCompleted = false
        var newVersion: String? = nil
        
        for _ in 1...15 {
            try? await Task.sleep(nanoseconds: 500_000_000) // Sleep 0.5s
            if let status = await client.getSyncJobStatus(jobId: syncJobId) {
                print("Job status: \(status.status), progress: \(status.progress)%")
                if status.status == "completed" {
                    jobCompleted = true
                    newVersion = status.result_metadata?.new_version
                    print("Model evaluation accuracy (F1): \(status.result_metadata?.accuracy_score ?? 0.0)")
                    break
                } else if status.status == "failed" {
                    print("FAILED: Sync job failed with error: \(status.result_metadata?.error ?? "nil")")
                    exit(1)
                }
            }
        }
        
        if !jobCompleted || newVersion == nil {
            print("FAILED: Sync learning job timed out or missing model version.")
            exit(1)
        }
        print("New Model Version generated: \(newVersion!)")
        
        print("\n4. Checking for model updates on client...")
        guard let updateCheck = await client.checkModelUpdate() else {
            print("FAILED: Client model update check failed")
            exit(1)
        }
        print("Update available: \(updateCheck.update_available)")
        print("Latest version: \(updateCheck.latest_version)")
        print("Download URL: \(updateCheck.download_url)")
        
        if !updateCheck.update_available || updateCheck.latest_version != newVersion {
            print("FAILED: Client did not detect the newly generated model.")
            exit(1)
        }
        
        print("\n5. Applying model update to client...")
        let applied = await client.applyModelUpdate(version: newVersion!)
        if !applied {
            print("FAILED: Model update application failed.")
            exit(1)
        }
        
        print("Applied model version: \(client.currentModelVersion)")
        if client.currentModelVersion != newVersion {
            print("FAILED: Client current version was not updated.")
            exit(1)
        }
        
        print("\n6. Fetching current active model metadata...")
        guard let currentModel = await client.fetchCurrentModel() else {
            print("FAILED: Failed to fetch current active model")
            exit(1)
        }
        print("Active model version on registry: \(currentModel.version)")
        print("Accuracy F1 score: \(currentModel.accuracy_score ?? 0.0)")
        if currentModel.version != newVersion {
            print("FAILED: Current active model in registry does not match.")
            exit(1)
        }
        
        print("\n7. Verifying trial feature logging with updated model version...")
        await client.createSession(species: .dog, tempId: "DOG-NEW-MODEL", notes: "Testing with model version \(newVersion!)")
        guard let newSession = client.currentSession else {
            print("FAILED: Failed to create session under new model.")
            exit(1)
        }
        await client.fetchCandidates(species: .dog)
        if client.candidates.isEmpty {
            print("FAILED: No candidates available.")
            exit(1)
        }
        let testCand = client.candidates[0]
        await client.recordTrial(candidateId: testCand.candidate_id, name: testCand.name, reaction: "reaction_yes")
        
        if client.trials.isEmpty {
            print("FAILED: No trials logged under new model.")
            exit(1)
        }
        
        // Wait briefly for server database flush
        try? await Task.sleep(nanoseconds: 500_000_000)
        print("SUCCESS: Phase 5 Batch Training & Model Distribution verified!")
        
        // --- Scenario 6: Internationalization & Localization Flow ---
        print("\n=== Scenario 6: Internationalization & Localization ===")
        
        print("\n1. Fetching available countries and languages...")
        await client.fetchCountries()
        await client.fetchLanguages()
        await client.fetchTTSProfiles()
        
        print("Countries available: \(client.availableCountries.count)")
        for c in client.availableCountries {
            print(" - \(c.name) (\(c.code))")
        }
        if client.availableCountries.isEmpty {
            print("FAILED: Countries list is empty.")
            exit(1)
        }
        
        if !client.availableCountries.contains(where: { $0.code == "US" }) || !client.availableCountries.contains(where: { $0.code == "JP" }) {
            print("FAILED: Missing JP or US default country seeds.")
            exit(1)
        }
        
        print("\n2. Configuring Client to United States & en-US locale...")
        client.selectedCountryCode = "US"
        client.selectedLanguageCode = "en-US"
        
        print("\n3. Creating Exploration Session in US locale...")
        await client.createSession(species: .dog, tempId: "DOG-US-TEST", notes: "Exploring names in United States context")
        guard let usSession = client.currentSession else {
            print("FAILED: Session creation failed.")
            exit(1)
        }
        print("Created US Session ID: \(usSession.session_id)")
        print("Session Country: \(usSession.country_code ?? "nil"), Language: \(usSession.language_code ?? "nil")")
        
        if usSession.country_code != "US" || usSession.language_code != "en-US" {
            print("FAILED: Session country or language not stored correctly.")
            exit(1)
        }
        
        print("\n4. Fetching Candidates in US locale...")
        await client.fetchCandidates(species: .dog)
        print("Candidates fetched: \(client.candidates.count)")
        for c in client.candidates {
            print(" - \(c.name) (ID: \(c.candidate_id))")
        }
        if client.candidates.isEmpty {
            print("FAILED: Candidates list is empty.")
            exit(1)
        }
        if !client.candidates.contains(where: { $0.name == "Max" }) {
            print("FAILED: Candidates should contain popular US name 'Max'.")
            exit(1)
        }
        
        print("\n5. Recording Trial for 'Max' with positive reaction...")
        guard let maxCandidate = client.candidates.first(where: { $0.name == "Max" }) else {
            print("FAILED: 'Max' candidate not found.")
            exit(1)
        }
        await client.recordTrial(candidateId: maxCandidate.candidate_id, name: maxCandidate.name, reaction: "reaction_yes")
        
        print("\n6. Refining Candidates and verifying English Nicknames...")
        await client.refineCandidates()
        let usRefined = client.rankedCandidates
        print("Refined Candidates in US locale:")
        for r in usRefined {
            print(" - \(r.name) (score: \(r.score)) - explanation: \(r.explanation ?? "nil")")
        }
        
        if !usRefined.contains(where: { $0.name == "Maxie" || $0.name == "Maxy" }) {
            print("FAILED: Failed to refine candidate 'Max' into English nickname 'Maxie' or 'Maxy'.")
            exit(1)
        }
        print("SUCCESS: English nickname generated successfully!")
        
        print("\n7. Requesting TTS Preview on English voice profile...")
        guard let enProfile = client.availableTTSProfiles.first(where: { $0.language_code == "en-US" }) else {
            print("FAILED: No en-US TTS profile found.")
            exit(1)
        }
        print("Requesting preview using voice profile: \(enProfile.voice_name) (ID: \(enProfile.id))")
        if let previewRes = await client.requestTTSPreview(text: "Hello Max", profileId: enProfile.id) {
            print("TTS Preview URL: \(previewRes.audio_url)")
            if !previewRes.audio_url.contains("exports/tts/") {
                print("FAILED: TTS Preview URL path is invalid.")
                exit(1)
            }
            print("SUCCESS: TTS preview generated at valid URL.")
        } else {
            print("FAILED: TTS preview request failed.")
            exit(1)
        }
        
        print("SUCCESS: Phase 6 Internationalization verified!")
        
        print("\n=== SUCCESS: All Scenario tests completed successfully! ===")
    }
}

