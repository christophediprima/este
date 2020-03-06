CREATE TYPE public.tada_parameter AS ENUM (
    'list',
    'item'
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
ALTER TABLE ONLY public.book
    ADD CONSTRAINT book_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.author(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.comment
    ADD CONSTRAINT comment_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.book(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.library
    ADD CONSTRAINT library_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.book(id) ON UPDATE CASCADE ON DELETE CASCADE;
