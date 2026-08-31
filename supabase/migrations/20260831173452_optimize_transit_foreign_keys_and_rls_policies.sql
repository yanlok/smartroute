create index transit_links_to_station_idx
  on public.transit_links (to_station_id);
create index transit_links_line_idx
  on public.transit_links (line_id);
create index route_templates_destination_idx
  on public.route_templates (destination_station_id);
create index route_template_segments_from_station_idx
  on public.route_template_segments (from_station_id);
create index route_template_segments_to_station_idx
  on public.route_template_segments (to_station_id);
create index route_template_segments_line_idx
  on public.route_template_segments (line_id);

drop policy "Admins can view profiles" on public.profiles;
alter policy "Users can view own profile"
  on public.profiles
  using (
    (select auth.uid()) = id
    or (select private.is_admin())
  );

drop policy "Admins can view preferences" on public.user_preferences;
