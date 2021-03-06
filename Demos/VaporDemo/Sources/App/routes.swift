import Vapor
import MeiliSearch

func routes(_ app: Application) throws {

    let client = try! MeiliSearch(Config(hostURL: "http://localhost:7700"))

    // 127.0.0.1:8080/index?uid=Movies
    app.get("index") { req -> EventLoopFuture<String> in

        /// Create a new void promise
        let promise = req.eventLoop.makePromise(of: String.self)

        /// Dispatch some work to happen on a background thread
        req.application.threadPool.submit { _ in

            guard let uid: String = req.query["uid"] else {
                promise.fail(Abort(.badRequest))
                return
            }

            client.getIndex(UID: uid) { result in

              switch result {
              case .success(let index):

                let encoder: JSONEncoder = JSONEncoder()
                let data: Data = try! encoder.encode(index)
                let dataString: String = String(decoding: data, as: UTF8.self)

                promise.succeed(dataString)

              case .failure(let error):
                promise.fail(error)
              }

            }

        }

        /// Wait for the future to be completed,
        /// then transform the result to a simple String
        return promise.futureResult
    }

    // 127.0.0.1:8080/search?query=botman
    app.get("search") { req -> EventLoopFuture<String> in

        /// Create a new void promise
        let promise = req.eventLoop.makePromise(of: String.self)

        /// Dispatch some work to happen on a background thread
        req.application.threadPool.submit { _ in

            guard let query: String = req.query["query"] else {
                promise.fail(Abort(.badRequest))
                return
            }

            let searchParameters = SearchParameters.query(query)

            client.search(UID: "movies", searchParameters) { result in

              switch result {
              case .success(let searchResult):

                let jsonData = try! JSONSerialization.data(
                  withJSONObject: searchResult.hits,
                  options: [])
                let dataString: String = String(decoding: jsonData, as: UTF8.self)

                promise.succeed(dataString)

              case .failure(let error):
                promise.fail(error)
              }

            }

        }

        /// Wait for the future to be completed,
        /// then transform the result to a simple String
        return promise.futureResult
    }

}
