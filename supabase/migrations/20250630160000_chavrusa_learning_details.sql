alter table public.chavrusa_listings
  add column if not exists learning_details text not null default '';
