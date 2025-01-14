## Rust Raymarcher

A Rust OpenGL raymarcher built on top of meshview. Made with Rust egui and glow. 

![Mandelbrot Fractal](img\Mandelbrot Fractal.png "Mandelbrot Fractal")

The raymarching logic is done in `main.frag.glsl`. Camera matrices and controls are handled in `camera.rs`. OpenGL API interactions are done in `main.rs`

Controls to adjust the camera position, look vector, and speed. Animation toggle that interpolates the Mandelbrot exponent from 0.0 through 20.0. When disabled, the exponent can also be controlled throguh the `exp` slider. For best results, use an exp of 6.0 through 8.0.

The iterations and detail sliders both control the level of detail on the SDF. The `iterations` slider controls the number of iterations the mandelbrot function checks for divergence. The `detail` slider controls the delta for which the raymarching engine will accept a collision. The default settings are enough to view most of the Mandelbrot, but to see more details on the mandelbrot, increase the `detail` slider by about 10. Note that increasing either of these sliders may result in a drop in framerate, as these calculations become expensive very quickly. 