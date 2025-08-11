const InfiniteScroll = {
  mounted() {
    this.loading = false;
    this.hasMore = this.el.dataset.hasMore === "true";

    const findScrollContainer = (el) => {
      let node = el.parentElement;
      while (node) {
        const style = window.getComputedStyle(node);
        const overflowY = style.overflowY;
        const isScrollable = overflowY === "auto" || overflowY === "scroll";
        if (isScrollable && node.scrollHeight > node.clientHeight) return node;
        node = node.parentElement;
      }
      return window; // fallback
    };

    this.scrollContainer = findScrollContainer(this.el);

    const triggerLoad = () => {
      if (this.loading || !this.hasMore) return;
      this.loading = true;
      this.pushEvent("load-more", {}, () => {
        this.loading = false;
        this.hasMore = this.el.dataset.hasMore === "true";
      });
    };

    if ("IntersectionObserver" in window && this.scrollContainer !== window) {
      this.observer = new IntersectionObserver(
        entries => {
          const entry = entries[0];
          if (entry.isIntersecting) triggerLoad();
        },
        {
          root: this.scrollContainer,
          rootMargin: "300px 0px",
          threshold: 0.0
        }
      );
      this.observer.observe(this.el);
    } else if ("IntersectionObserver" in window) {
      this.observer = new IntersectionObserver(
        entries => {
          const entry = entries[0];
          if (entry.isIntersecting) triggerLoad();
        },
        {
          root: null,
          rootMargin: "300px 0px",
          threshold: 0.0
        }
      );
      this.observer.observe(this.el);
    } else {
      // Fallback: attach to the scroll container
      const onScroll = () => {
        if (this.scrollContainer === window) {
          const rect = this.el.getBoundingClientRect();
          const nearBottom = rect.top < (window.innerHeight + 300);
          if (nearBottom) triggerLoad();
        } else {
          const sc = this.scrollContainer;
          const distanceToBottom = sc.scrollHeight - sc.scrollTop - sc.clientHeight;
          if (distanceToBottom < 300) triggerLoad();
        }
      };
      this.onScroll = onScroll;
      const target = this.scrollContainer === window ? window : this.scrollContainer;
      target.addEventListener("scroll", this.onScroll, { passive: true });
      this.onScroll();
    }
  },
  updated() {
    this.hasMore = this.el.dataset.hasMore === "true";
    if (!this.hasMore && this.observer) {
      this.observer.disconnect();
    }
  },
  destroyed() {
    if (this.observer) this.observer.disconnect();
    if (this.onScroll) {
      const target = this.scrollContainer === window ? window : this.scrollContainer;
      target.removeEventListener("scroll", this.onScroll);
    }
  }
};

const IntersectionObserver = {
  mounted() {
    // Only proceed if IntersectionObserver is supported
    if (!("IntersectionObserver" in window)) {
      return;
    }

    // Check if this element should trigger loading more genres
    if (this.el.dataset.loadMore === "true") {
      this.observer = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              // Trigger the load_more_genres event
              this.pushEvent("load_more_genres", {});
            }
          });
        },
        {
          root: null,
          rootMargin: "100px 0px", // Start loading when 100px away from viewport
          threshold: 0.1
        }
      );

      this.observer.observe(this.el);
    }
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }
};

export default {
  InfiniteScroll: InfiniteScroll,
  IntersectionObserver: IntersectionObserver
};
