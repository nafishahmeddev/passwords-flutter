# Passwords

A secure, feature-rich password manager app built with Flutter.

## Features

- **Secure Storage**: Safely store your passwords and account details
- **Biometric Authentication**: Unlock the app with fingerprint or face recognition
- **Auto-lock**: Automatically lock the app after a configurable period of inactivity
- **Dark/Light Theme**: Choose between light, dark, or system theme
- **Password Generator**: Create strong, custom passwords
- **Bottom Navigation**: Easy access to accounts, password generator, and settings

## App Structure

The app is organized using a clean architecture approach:

- **presentation**: UI layer with screens and widgets
- **business**: Provider classes and business logic 
- **data**: Data models, repositories, and services

## Authentication

The app supports PIN and biometric authentication. All security settings can be configured in the Settings screen.

## Navigation

The app now features a bottom navigation with three main sections:

1. **Accounts**: View, add, and manage your saved accounts
2. **Password Generator**: Generate secure passwords with customizable options
3. **Settings**: Configure app appearance, security, and auto-lock settings
