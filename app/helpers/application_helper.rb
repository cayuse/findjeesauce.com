module ApplicationHelper
  # The finder with a flavor chosen (nil clears it), keeping the search.
  def flavor_filter_path(flavor)
    finder_root_path(request.query_parameters.slice("q", "lat", "lng").merge("flavor" => flavor&.slug).compact_blank)
  end

  # A flavor's lid as a round icon. Decorative wherever its name is also shown.
  def lid_icon(flavor, size:, alt: "", **options)
    image_tag flavor.lid, alt: alt, width: size, height: size, loading: "lazy", decoding: "async",
              class: class_names("shrink-0 rounded-full", options.delete(:class)), **options
  end

  # "Cilantro Lime" as a pill with its lid; the chosen flavor stands out.
  def flavor_pill(name, chosen: false)
    flavor = Flavor.named(name)
    tag.li(class: class_names("inline-flex items-center gap-1.5 rounded-full border py-0.5 pr-2.5 text-xs",
                              flavor ? "pl-0.5" : "pl-2.5",
                              chosen ? "border-ink bg-ink font-semibold text-white" : "border-line bg-white")) do
      safe_join([ (lid_icon(flavor, size: 20) if flavor), name ].compact)
    end
  end
end
