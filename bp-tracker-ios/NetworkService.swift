import Foundation

// Actor to handle network requests safely in concurrent environments
actor NetworkService {
    // Replace with your actual API Gateway Invoke URL
    private let baseURL = "https://your-api-gateway-id.execute-api.your-region.amazonaws.com"

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // Custom error type for networking issues
    enum NetworkError: Error {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingError(Error)
        case encodingError(Error)
        case serverError(statusCode: Int, message: String?)
    }

    init(session: URLSession = .shared) {
        self.session = session

        // Configure JSON Decoder
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601withFractionalSeconds // Use our custom strategy

        // Configure JSON Encoder
        self.encoder = JSONEncoder()
        // Use default encoding strategies for now
    }

    // MARK: - API Calls

    /// Fetches all blood pressure readings from the backend.
    func fetchReadings() async throws -> [Reading] {
        guard let url = URL(string: "\(baseURL)/api/readings") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Add any necessary headers here, e.g., authorization if needed later
        // request.setValue("Bearer YOUR_TOKEN", forHTTPHeaderField: "Authorization")

        let (data, response) = try await performRequest(request)

        do {
            let readings = try decoder.decode([Reading].self, from: data)
            return readings
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    /// Submits a new set of blood pressure readings.
    /// Note: The current backend /submit endpoint returns stats, classification, etc.
    /// This function currently discards that response, but it could be decoded if needed.
    func submitReading(input: ReadingInput) async throws {
        guard let url = URL(string: "\(baseURL)/submit") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(input)
        } catch {
            throw NetworkError.encodingError(error)
        }

        // Perform request and ignore the response body for now
        _ = try await performRequest(request)

        // If we needed the response:
        /*
         let (data, response) = try await performRequest(request)
         do {
             // Define a struct matching the submit response if needed
             let submitResponse = try decoder.decode(SubmitResponse.self, from: data)
             print("Submit successful: \(submitResponse)")
         } catch {
             throw NetworkError.decodingError(error)
         }
         */
    }

    // MARK: - Private Helper

    /// Performs the URLSession data task and handles basic response validation.
    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Check for successful status codes (2xx)
            guard (200...299).contains(httpResponse.statusCode) else {
                // Attempt to decode server error message if available
                var serverMessage: String? = nil
                if let errorPayload = try? decoder.decode([String: String].self, from: data) {
                    serverMessage = errorPayload["error"] ?? errorPayload["message"]
                }
                 if serverMessage == nil {
                     serverMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                 }
                throw NetworkError.serverError(statusCode: httpResponse.statusCode, message: serverMessage)
            }

            return (data, httpResponse)

        } catch let error as NetworkError {
            // Re-throw specific network errors
             print("NetworkService Error: \(error)")
            throw error
        } catch {
            // Wrap other errors (e.g., connectivity issues)
             print("NetworkService Error: \(error)")
            throw NetworkError.requestFailed(error)
        }
    }
}
