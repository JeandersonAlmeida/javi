// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import hooks from "./hooks"

// Audio Control Hook
const AudioControl = {
  mounted() {
    this.audio = document.getElementById('onboarding-audio');
    this.audio.volume = 0.3; // Set volume to 30%

    // Auto-play when page loads
    this.startAnimatedSoundtrack();
  },

  startAnimatedSoundtrack() {
    // Try to play the external animated soundtrack
    this.audio.play().catch(e => {
      console.log('Could not auto-play animated soundtrack:', e);
      // Fallback: try to play when user interacts
    });
  },

  updated() {
    // Check if audio should be playing based on the data attribute
    const isPlaying = this.el.getAttribute('data-audio-playing') === 'true';

    if (isPlaying) {
      // Start audio
      this.audio.play().catch(e => {
        console.log('Audio play failed:', e);
      });
    } else {
      // Stop audio
      this.audio.pause();
    }
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: { AudioControl, ...hooks }
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Import page-specific scripts
import "./onboarding.js";
import "./landing.js";
import "./profile.js";

// Poster carousel functionality
function initPosterCarousels() {
  const carousels = document.querySelectorAll('.poster-carousel');

  carousels.forEach((carousel, carouselIndex) => {
    const slides = carousel.querySelectorAll('.poster-slide');
    if (slides.length <= 1) return;

    let currentSlide = 0;

    // Clear any existing intervals for this carousel
    if (carousel.intervalId) {
      clearInterval(carousel.intervalId);
    }

    // Show first slide initially
    slides.forEach(slide => slide.classList.remove('active'));
    slides[0].classList.add('active');

    // Function to cycle through slides
    function nextSlide() {
      slides[currentSlide].classList.remove('active');
      currentSlide = (currentSlide + 1) % slides.length;
      slides[currentSlide].classList.add('active');
    }

    // Change slide every 3 seconds and store the interval ID
    carousel.intervalId = setInterval(nextSlide, 3000);
  });
}

// Initialize carousels when page loads
document.addEventListener('DOMContentLoaded', initPosterCarousels);

// Re-initialize carousels after LiveView updates
document.addEventListener('phx:update', initPosterCarousels);

