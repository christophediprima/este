CREATE SCHEMA tadalist;
CREATE TYPE public.tada_parameter AS ENUM (
    'list',
    'item'
);
CREATE TABLE tadalist.tada_shares (
    user_id text NOT NULL,
    tada_id uuid NOT NULL
);
CREATE FUNCTION public.share_is_tada_owner(tada_shares_row tadalist.tada_shares) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    SELECT EXISTS (
        SELECT owner_id
        FROM tadaList.tada
        WHERE (owner_id = tada_shares_row.user_id AND tada_id = tada_shares_row.tada_id)
    )
$$;
CREATE FUNCTION tadalist.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  _new."updated_at" = NOW();
  RETURN _new;
END;
$$;
CREATE FUNCTION tadalist.share_is_tada_owner(tada_shares_row tadalist.tada_shares) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    SELECT EXISTS (
        SELECT owner_id
        FROM tadaList.tada
        WHERE (owner_id = tada_shares_row.user_id AND tada_id = tada_shares_row.tada_id)
    )
$$;
CREATE TABLE public.author (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    tadaweb_id text NOT NULL
);
CREATE TABLE public.book (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    title text NOT NULL,
    author_id uuid NOT NULL
);
CREATE TABLE public.comment (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    content text NOT NULL,
    book_id uuid NOT NULL
);
CREATE TABLE public.library (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    book_id uuid NOT NULL
);
CREATE TABLE tadalist.tada (
    tada_id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    updated_at date DEFAULT now() NOT NULL,
    created_at date DEFAULT now() NOT NULL,
    minimap_url text NOT NULL,
    owner_id text NOT NULL
);
CREATE TABLE tadalist.tada_parameters (
    uuid uuid NOT NULL,
    label text NOT NULL,
    updated_at date DEFAULT now() NOT NULL,
    type public.tada_parameter NOT NULL,
    data json NOT NULL,
    tada_id uuid NOT NULL
);
CREATE TABLE tadalist.tada_tags (
    tada_id uuid NOT NULL,
    name text NOT NULL
);
CREATE TABLE tadalist.tag (
    name text NOT NULL
);
CREATE TABLE tadalist.team (
    team_id text NOT NULL,
    name text NOT NULL
);
CREATE TABLE tadalist."user" (
    user_id text DEFAULT public.gen_random_uuid() NOT NULL,
    display_name text NOT NULL,
    avatar_img text NOT NULL,
    team_id text NOT NULL
);
ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_tadaweb_id_key UNIQUE (tadaweb_id);
ALTER TABLE ONLY public.book
    ADD CONSTRAINT book_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.library
    ADD CONSTRAINT library_pkey PRIMARY KEY (id);
ALTER TABLE ONLY tadalist.tada_parameters
    ADD CONSTRAINT tada_parameters_pkey PRIMARY KEY (uuid);
ALTER TABLE ONLY tadalist.tada
    ADD CONSTRAINT tada_pkey PRIMARY KEY (tada_id);
ALTER TABLE ONLY tadalist.tada_shares
    ADD CONSTRAINT tada_shares_pkey PRIMARY KEY (user_id, tada_id);
ALTER TABLE ONLY tadalist.tada
    ADD CONSTRAINT "tada_tadaId_key" UNIQUE (tada_id);
ALTER TABLE ONLY tadalist.tada_tags
    ADD CONSTRAINT tada_tags_pkey PRIMARY KEY (tada_id, name);
ALTER TABLE ONLY tadalist.tag
    ADD CONSTRAINT tag_pkey PRIMARY KEY (name);
ALTER TABLE ONLY tadalist.team
    ADD CONSTRAINT team_pkey PRIMARY KEY (team_id);
ALTER TABLE ONLY tadalist.team
    ADD CONSTRAINT "team_teamId_key" UNIQUE (team_id);
ALTER TABLE ONLY tadalist."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (user_id);
ALTER TABLE ONLY tadalist."user"
    ADD CONSTRAINT "user_userId_key" UNIQUE (user_id);
CREATE TRIGGER set_tadalist_tada_parameters_updated_at BEFORE UPDATE ON tadalist.tada_parameters FOR EACH ROW EXECUTE FUNCTION tadalist.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_tadalist_tada_parameters_updated_at ON tadalist.tada_parameters IS 'trigger to set value of column "updated_at" to current timestamp on row update';
ALTER TABLE ONLY public.book
    ADD CONSTRAINT book_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.author(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.comment
    ADD CONSTRAINT comment_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.book(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.library
    ADD CONSTRAINT library_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.book(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY tadalist.tada
    ADD CONSTRAINT "tada_ownerId_fkey" FOREIGN KEY (owner_id) REFERENCES tadalist."user"(user_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY tadalist.tada_parameters
    ADD CONSTRAINT tada_parameters_tada_id_fkey FOREIGN KEY (tada_id) REFERENCES tadalist.tada(tada_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY tadalist.tada_shares
    ADD CONSTRAINT "tada_shares_tadaId_fkey" FOREIGN KEY (tada_id) REFERENCES tadalist.tada(tada_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY tadalist.tada_shares
    ADD CONSTRAINT "tada_shares_userId_fkey" FOREIGN KEY (user_id) REFERENCES tadalist."user"(user_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY tadalist.tada_tags
    ADD CONSTRAINT "tada_tags_tadaId_fkey" FOREIGN KEY (tada_id) REFERENCES tadalist.tada(tada_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY tadalist.tada_tags
    ADD CONSTRAINT tada_tags_tag_name_fkey FOREIGN KEY (name) REFERENCES tadalist.tag(name) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY tadalist."user"
    ADD CONSTRAINT "user_teamId_fkey" FOREIGN KEY (team_id) REFERENCES tadalist.team(team_id) ON UPDATE CASCADE ON DELETE CASCADE;
