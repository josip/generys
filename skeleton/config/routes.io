Router do (
  # Last defined route has the smallest priority
  # It's recommended not to use defaultRoutes() - it can access all methods on a controller
  # use resource() or connect() to allow only specific methods
  
  defaultRoutes
  fileServerRoute
)
