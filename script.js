// Destnly - Modern Dating App Website JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Initialize all functionality
    initScrollAnimations();
    initSmoothScrolling();
    initHoverEffects();
    initLoadingAnimation();
    initMobileMenu();

    // Scroll-based animations
    function initScrollAnimations() {
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('fade-in-up');
                }
            });
        }, observerOptions);

        // Observe elements that should animate on scroll
        const animatedElements = document.querySelectorAll('.feature-card, .testimonial-card, .step-card');
        animatedElements.forEach(el => {
            observer.observe(el);
        });
    }

    // Smooth scrolling for navigation links
    function initSmoothScrolling() {
        const navLinks = document.querySelectorAll('a[href^="#"]');

        navLinks.forEach(link => {
            link.addEventListener('click', function(e) {
                const targetId = this.getAttribute('href');
                const targetSection = document.querySelector(targetId);

                if (targetSection) {
                    e.preventDefault();
                    const offsetTop = targetSection.offsetTop - 80; // Account for fixed nav

                    window.scrollTo({
                        top: offsetTop,
                        behavior: 'smooth'
                    });
                }
            });
        });
    }

    // Hover effects for interactive elements
    function initHoverEffects() {
        // Add hover effects to feature cards
        const featureCards = document.querySelectorAll('.feature-card');
        featureCards.forEach(card => {
            card.addEventListener('mouseenter', function() {
                this.style.transform = 'translateY(-10px) scale(1.02)';
                this.style.boxShadow = '0 25px 50px rgba(0, 0, 0, 0.15)';
            });

            card.addEventListener('mouseleave', function() {
                this.style.transform = 'translateY(0) scale(1)';
                this.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.1)';
            });
        });

        // Add hover effects to testimonial cards
        const testimonialCards = document.querySelectorAll('.testimonial-card');
        testimonialCards.forEach(card => {
            card.addEventListener('mouseenter', function() {
                this.style.transform = 'translateY(-5px)';
                this.style.boxShadow = '0 20px 40px rgba(0, 0, 0, 0.1)';
            });

            card.addEventListener('mouseleave', function() {
                this.style.transform = 'translateY(0)';
                this.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.05)';
            });
        });

        // Button hover effects
        const buttons = document.querySelectorAll('.btn-primary, .bg-gradient-to-r');
        buttons.forEach(button => {
            button.addEventListener('mouseenter', function() {
                this.style.transform = 'scale(1.05)';
            });

            button.addEventListener('mouseleave', function() {
                this.style.transform = 'scale(1)';
            });
        });
    }

    // Loading animation
    function initLoadingAnimation() {
        // Add loading class to body initially
        document.body.classList.add('loading');

        // Remove loading class after a short delay to trigger animations
        setTimeout(() => {
            document.body.classList.remove('loading');
        }, 100);
    }

    // Mobile menu functionality (if needed for future expansion)
    function initMobileMenu() {
        // This can be expanded if mobile menu is added
        const nav = document.querySelector('nav');
        let lastScrollTop = 0;

        window.addEventListener('scroll', function() {
            const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

            if (scrollTop > lastScrollTop && scrollTop > 100) {
                // Scrolling down - hide nav
                nav.style.transform = 'translateY(-100%)';
            } else {
                // Scrolling up - show nav
                nav.style.transform = 'translateY(0)';
            }

            lastScrollTop = scrollTop;
        });
    }

    // Parallax effect for hero section (optional enhancement)
    function initParallaxEffect() {
        const hero = document.querySelector('.hero');
        if (hero) {
            window.addEventListener('scroll', function() {
                const scrolled = window.pageYOffset;
                const rate = scrolled * -0.5;
                hero.style.transform = `translateY(${rate}px)`;
            });
        }
    }

    // Form validation for email signup (if added later)
    function validateEmail(email) {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
    }

    // Analytics tracking (placeholder for future implementation)
    function trackEvent(eventName, eventData) {
        // Placeholder for analytics implementation
        console.log('Event tracked:', eventName, eventData);
    }

    // Lazy loading for images (performance optimization)
    function initLazyLoading() {
        const images = document.querySelectorAll('img[data-src]');

        const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    img.src = img.dataset.src;
                    img.classList.remove('lazy');
                    observer.unobserve(img);
                }
            });
        });

        images.forEach(img => imageObserver.observe(img));
    }

    // Accessibility improvements
    function initAccessibility() {
        // Add focus trap for modals (if modals are added)
        // Add keyboard navigation support
        // Add screen reader support

        // Skip to main content link (can be added to HTML)
        const skipLink = document.createElement('a');
        skipLink.href = '#main-content';
        skipLink.textContent = 'Skip to main content';
        skipLink.className = 'sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-pink-500 text-white px-4 py-2 rounded z-50';
        document.body.insertBefore(skipLink, document.body.firstChild);
    }

    // Performance monitoring
    function initPerformanceMonitoring() {
        // Monitor page load times
        window.addEventListener('load', function() {
            const perfData = performance.getEntriesByType('navigation')[0];
            console.log('Page load time:', perfData.loadEventEnd - perfData.loadEventStart, 'ms');
        });
    }

    // Initialize additional features if needed
    function initAdvancedFeatures() {
        initParallaxEffect();
        initLazyLoading();
        initAccessibility();
        initPerformanceMonitoring();
    }

    // Call advanced features initialization
    initAdvancedFeatures();
    document.body.style.overflow = 'auto';
});


// Close modal when clicking outside
window.addEventListener('click', function(e) {
    if (e.target === helpModal) {
        helpModal.style.display = 'none';
        document.body.style.overflow = 'auto';
    }
});


// Smooth scrolling for navigation
function initSmoothScrolling() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                e.preventDefault();
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// Enhanced hover effects
function initHoverEffects() {
    // Add floating animation to app preview images
    document.querySelectorAll('.app-preview img').forEach(img => {
        img.addEventListener('mouseenter', function() {
            this.style.animation = 'float 3s ease-in-out infinite';
        });

        img.addEventListener('mouseleave', function() {
            this.style.animation = 'none';
        });
    });

    // Button pulse effect on hover
    document.querySelectorAll('.btn-primary, .btn-secondary').forEach(btn => {
        btn.addEventListener('mouseenter', function() {
            this.style.animation = 'pulse 2s infinite';
        });

        btn.addEventListener('mouseleave', function() {
            this.style.animation = 'none';
        });
    });
}

// Loading animation
function initLoadingAnimation() {
    const elements = document.querySelectorAll('.loading');
    elements.forEach((el, index) => {
        setTimeout(() => {
            el.classList.add('fade-up');
        }, index * 200);
    });
}

// Parallax effect for hero section
window.addEventListener('scroll', function() {
    const scrolled = window.pageYOffset;
    const heroImage = document.querySelector('.hero img');

    if (heroImage) {
        heroImage.style.transform = `translateY(${scrolled * 0.2}px)`;
    }
});

// Dynamic background gradient based on scroll
window.addEventListener('scroll', function() {
    const scrolled = window.pageYOffset;
    const hero = document.querySelector('.hero');

    if (hero && scrolled < window.innerHeight) {
        const opacity = 1 - (scrolled / window.innerHeight) * 0.3;
        hero.style.opacity = opacity;
    }
});

// Mobile menu toggle (if needed in future)
function toggleMobileMenu() {
    const nav = document.querySelector('nav');
    if (nav) {
        nav.classList.toggle('active');
    }
}

// Form validation for download section (placeholder)
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

// Add click tracking for analytics (placeholder)
document.addEventListener('click', function(e) {
    if (e.target.matches('.btn-primary, .btn-secondary')) {
        // Track button clicks
        console.log('Button clicked:', e.target.textContent.trim());
    }
});

// Keyboard navigation
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        const modals = document.querySelectorAll('.modal');
        modals.forEach(modal => {
            modal.style.display = 'none';
        });
        document.body.style.overflow = 'auto';
    }
});

// Performance optimization: Lazy load images
function lazyLoadImages() {
    const images = document.querySelectorAll('img[data-src]');

    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.remove('lazy');
                observer.unobserve(img);
            }
        });
    });

    images.forEach(img => imageObserver.observe(img));
}

// Initialize lazy loading
lazyLoadImages();