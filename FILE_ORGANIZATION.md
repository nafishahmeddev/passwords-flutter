# Passwords App - File Organization

## Overview
This document describes the organization of files in the Passwords app, highlighting the key components and their relationships.

## Key Changes
- Removed duplicate files and consolidated logic
- Switched from a tabbed interface to a card-based UI
- Simplified navigation with better organization
- Enhanced visual appearance with card styling

## File Structure

### Main Components

1. **Screens** (`lib/presentation/screens/`)
   - `account_list_screen_card.dart`: The main account list screen with card UI
   - `home_screen.dart`: Main container with bottom navigation
   - `password_generator_screen.dart`: For generating secure passwords
   - `settings_screen.dart`: App settings and preferences
   - `account_detail_screen.dart`: Viewing account details
   - `account_form_screen.dart`: Form for creating/editing accounts

2. **Widgets** (`lib/presentation/widgets/`)
   - `account_list_item.dart`: Card widget for displaying accounts in list
   - Various field-related widgets in subfolders

3. **Business Logic** (`lib/business/`)
   - Providers for state management
   - Services for business logic operations

4. **Data Layer** (`lib/data/`)
   - Repositories for data access
   - Models for data structures
   - Services for external interactions

## UI Components

### Account List
The new card-based account list provides:
- Modern, elevated cards with dynamic coloring
- Swipe-to-delete functionality
- Search capability
- Favorites filtering
- Long-press options menu

### Navigation
- Bottom navigation bar with Accounts, Generate, and Settings tabs
- FAB for adding new accounts when on the Accounts tab

### Account Details
- View, edit, and manage accounts with all associated fields
- Secure handling of sensitive information