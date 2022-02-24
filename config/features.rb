# frozen_string_literal: true

Flipflop.configure do
    feature :hyrax_autopopulation,
            default: false,
            description: "Allow works to be created via autopopulation using DOI & ORCID IDs"
end