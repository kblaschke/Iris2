INCLUDE_DIRECTORIES(../include)

set(PagedGeometry_SRCS BatchedGeometry.cpp BatchPage.cpp  GrassLoader.cpp ImpostorPage.cpp PagedGeometry.cpp PropertyMaps.cpp StaticBillboardSet.cpp TreeLoader2D.cpp TreeLoader3D.cpp)

ADD_LIBRARY(PagedGeometry SHARED ${PagedGeometry_SRCS})
