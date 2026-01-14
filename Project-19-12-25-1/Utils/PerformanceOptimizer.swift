import Foundation
import CoreData

class PerformanceOptimizer {
    static func optimizeFetchRequest<T: NSManagedObject>(_ request: NSFetchRequest<T>, limit: Int? = nil, offset: Int = 0) -> NSFetchRequest<T> {
        if let limit = limit {
            request.fetchLimit = limit
            request.fetchOffset = offset
        }
        
        // Batch size for better performance
        request.fetchBatchSize = AppConstants.Defaults.itemsPerPage
        
        // Only fetch needed properties if possible
        request.returnsObjectsAsFaults = false
        
        return request
    }
    
    static func paginatedFetch<T: NSManagedObject>(
        entityName: String,
        context: NSManagedObjectContext,
        sortDescriptors: [NSSortDescriptor],
        page: Int,
        pageSize: Int = AppConstants.Defaults.itemsPerPage
    ) -> [T] {
        let request = NSFetchRequest<T>(entityName: entityName)
        request.sortDescriptors = sortDescriptors
        
        let offset = page * pageSize
        request.fetchLimit = pageSize
        request.fetchOffset = offset
        request.fetchBatchSize = pageSize
        request.returnsObjectsAsFaults = false
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching paginated data: \(error)")
            return []
        }
    }
}
