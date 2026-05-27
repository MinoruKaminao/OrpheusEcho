import Foundation
import LostPetNameFinder

@main
@MainActor
struct TestRunner {
    static func main() async {
        print("=== Starting API Client Connection Test ===")
        
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
            print(" - \(r.name): score \(r.score), uncertain \(r.uncertainty_flag)")
        }
        if ranked.isEmpty {
            print("FAILED: No ranked candidates returned.")
            exit(1)
        }
        
        // 4. Refine Candidates
        print("\n--- 4. Refining Candidates ---")
        await client.refineCandidates()
        let refined = client.rankedCandidates
        print("Refined Candidates:")
        for r in refined {
            print(" - \(r.name): score \(r.score), uncertain \(r.uncertainty_flag)")
        }
        
        // 5. Close Session
        print("\n--- 5. Closing Session ---")
        await client.closeSession()
        let closedSession = client.currentSession
        if let status = closedSession?.status {
            print("Session status after close: \(status)")
            if status == .closed {
                print("\n=== SUCCESS: All API operations completed successfully! ===")
            } else {
                print("FAILED: Session status is not closed.")
                exit(1)
            }
        } else {
            print("FAILED: Current session is nil.")
            exit(1)
        }
    }
}
