import Foundation
import Combine

final class DownloadService {

	func fetch(request: URLRequest, session: URLSession) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
		return session
			.dataTaskPublisher(for: request)
			.tryMap { output in
				guard let httpResponse = output.response as? HTTPURLResponse else {
					return (output.data, output.response)
				}
				guard (200..<400).contains(httpResponse.statusCode) else {
					throw URLError(.badServerResponse)
				}
				return (output.data, output.response)
			}
			.eraseToAnyPublisher()
	}
}


