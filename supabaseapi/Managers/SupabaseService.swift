import Foundation
import Supabase

struct SupabaseService {
    let client: SupabaseClient
    init() {
        let url = URL(string: "https://jbohiwiupbmiblkqshze.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impib2hpd2l1cGJtaWJsa3FzaHplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkzODE2MzMsImV4cCI6MjA3NDk1NzYzM30.DYecLFxg3yu-YdFYg1GaLFye4IuYfISuEbYRRaOnpUk"
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
