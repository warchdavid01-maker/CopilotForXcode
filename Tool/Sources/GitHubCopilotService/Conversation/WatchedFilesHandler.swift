import JSONRPC
import Combine

public protocol WatchedFilesHandler {
    var onWatchedFiles: PassthroughSubject<(WatchedFilesRequest, (AnyJSONRPCResponse) -> Void), Never> { get }
    func handleWatchedFiles(_ request: WatchedFilesRequest, completion: @escaping (AnyJSONRPCResponse) -> Void)
}

public final class WatchedFilesHandlerImpl: WatchedFilesHandler {
    public static let shared = WatchedFilesHandlerImpl()
    
    public let onWatchedFiles: PassthroughSubject<(WatchedFilesRequest, (AnyJSONRPCResponse) -> Void), Never> = .init()

    public func handleWatchedFiles(_ request: WatchedFilesRequest, completion: @escaping (AnyJSONRPCResponse) -> Void) {
        onWatchedFiles.send((request, completion))
    }
}
