# Topotrack

A script to plot GPS tracks onto 2D or 3D topographic maps.

## Install

- This script has been developed with [R](https://www.r-project.org/) version `3.6.3`.
- This script requires [XQuartz](https://www.xquartz.org/) to render the 3D view on macOS 10.9 or later.

### Dependencies

- [`av`](https://cran.r-project.org/web/packages/av/index.html): Tools for working with audio and video.
- [`elevatr@0.2.0`](https://cran.r-project.org/web/packages/elevatr/index.html): Tools for accessing elevation data from various APIs.
- [`plyr`](https://cran.r-project.org/web/packages/plyr/index.html): Tools for splitting, applying, and combining data.
- [`raster`](https://cran.r-project.org/web/packages/raster/index.html): Tools for reading, writing, manipulating, analyzing and modeling of spatial data.
- [`rayshader`](https://cran.r-project.org/web/packages/rayshader/index.html): Tools for creating and visualizing data in 2D and 3D.
- [`sf`](https://cran.r-project.org/web/packages/sf/index.html): Standardized way to encode spatial vector data.
- [`sp`](https://cran.r-project.org/web/packages/sp/index.html): Tools for working with spatial data.
- [`XML`](https://cran.r-project.org/web/packages/XML/index.html): Tools for parsing and creating XML.

## Usage

- Replace the GPS file `track.gpx` with your own track in the working directory.
- Replace the path to the working directory in `setwd`.

## Credits

- [Tyler Morgan-Wall](https://www.tylermw.com/) for their contribution to the indespensible `rayshader` package.
- [Elizabeth Easter](https://www.elizabetheaster.com/) for their insightful article [«Guide to creating 3D maps of GPS routes using Rayshader»](https://www.elizabetheaster.com/blog/2019/07/19/GPS_Routes_Plotted_on_Realistic_3D_Map).
- [Anna Wiederkehr](https://annawiederkehr.com/) for their debugging support.

## Contributing

- Please submit questions and comments as [issues](https://github.com/wiederkehr/topotrack/issues).

## License

MIT License

Copyright (c) 2021 Benjamin Wiederkehr

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
