#!/bin/bash

validate_domain() {
    if [[ ! $1 =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}Invalid domain format${NC}"
        return 1
    fi
    return 0
}

validate_email() {
    if [[ ! $1 =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo -e "${RED}Invalid email format${NC}"
        return 1
    fi
    return 0
}

validate_username() {
    if [[ -z "$1" ]] || [[ "$1" =~ ^[[:space:]]*$ ]]; then
        echo -e "${RED}Username cannot be empty${NC}"
        return 1
    fi
    return 0
}