# Landing Module

This module contains the landing page for the Javi application.

## Structure

- `landing_controller.ex` - Controller that handles the landing page route
- `landing_html.ex` - HTML module that defines the landing page views
- `landing_html/index.html.heex` - The main landing page template

## Features

The landing page includes:

- **Modern Design**: Gradient backgrounds with animated blob elements
- **Responsive Layout**: Optimized for both mobile and desktop views
- **Interactive Elements**: Hover effects and smooth transitions
- **Mobile Navigation**: Collapsible mobile menu with hamburger button
- **Call-to-Action Buttons**: Prominent buttons for registration and login
- **Feature Showcase**: Grid layout showcasing app features
- **Statistics Section**: Displaying user engagement metrics
- **Footer**: Complete footer with links and company information

## Routes

- `GET /` - Shows the landing page for unauthenticated users
- Redirects authenticated users to `/home`

## Styling

The landing page uses:
- Tailwind CSS for styling
- Custom CSS animations for blob effects
- Glass morphism effects for modern UI
- Responsive design patterns
- Smooth scrolling for anchor links

## JavaScript

Includes mobile menu functionality:
- Toggle mobile menu visibility
- Close menu when clicking links
- Close menu when clicking outside 