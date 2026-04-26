--
-- PostgreSQL database dump
--

\restrict fdhJl2hibvIDMWbS92dPcIVsIA2ddfld4seS0xLL7EWMIxHWUJvsqKSOqhVG1Ax

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: authors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.authors (
    id text NOT NULL,
    first_name text,
    last_name text
);


ALTER TABLE public.authors OWNER TO postgres;

--
-- Name: books; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.books (
    id text NOT NULL,
    title text,
    author_id text,
    category_id text,
    description text,
    rating numeric,
    publication_year numeric,
    copies_owned numeric,
    image text,
    language text,
    pages numeric,
    rating_count numeric
);


ALTER TABLE public.books OWNER TO postgres;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    id text NOT NULL,
    name text,
    image_url text
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: fine_payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fine_payments (
    id text NOT NULL,
    fine_id text,
    member_id text,
    payment_date date,
    payment_amount numeric,
    payment_method text,
    handled_by text,
    notes text,
    created_at timestamp without time zone
);


ALTER TABLE public.fine_payments OWNER TO postgres;

--
-- Name: fines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fines (
    id text NOT NULL,
    member_id text,
    loan_id text,
    fine_date date,
    fine_amount numeric,
    status text,
    reason text,
    due_date date,
    paid_at timestamp without time zone,
    payment_method text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.fines OWNER TO postgres;

--
-- Name: interactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.interactions (
    id integer NOT NULL,
    user_id text,
    book_id text,
    interaction_type character varying,
    created_at timestamp with time zone
);


ALTER TABLE public.interactions OWNER TO postgres;

--
-- Name: interactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.interactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.interactions_id_seq OWNER TO postgres;

--
-- Name: interactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.interactions_id_seq OWNED BY public.interactions.id;


--
-- Name: loans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loans (
    id text NOT NULL,
    book_id text,
    member_id text,
    loan_date date,
    returned_date date
);


ALTER TABLE public.loans OWNER TO postgres;

--
-- Name: reservations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservations (
    id text NOT NULL,
    book_id text,
    member_id text,
    reservation_date date,
    status text
);


ALTER TABLE public.reservations OWNER TO postgres;

--
-- Name: settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.settings (
    id text NOT NULL,
    loan_period_days integer NOT NULL,
    max_books_per_user integer NOT NULL,
    grace_period_days integer NOT NULL,
    daily_fine_rate numeric(10,2) NOT NULL,
    max_fine_cap numeric(10,2) NOT NULL,
    block_on_unpaid_fines boolean NOT NULL,
    fine_threshold numeric(10,2) NOT NULL,
    send_notifications boolean NOT NULL,
    notification_days_before_due integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.settings OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id text NOT NULL,
    member_id text,
    name character varying(100),
    email character varying(100),
    password bytea,
    phone character varying(20),
    address text,
    profile_image text,
    joined_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: interactions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactions ALTER COLUMN id SET DEFAULT nextval('public.interactions_id_seq'::regclass);


--
-- Data for Name: authors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.authors (id, first_name, last_name) FROM stdin;
\.


--
-- Data for Name: books; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.books (id, title, author_id, category_id, description, rating, publication_year, copies_owned, image, language, pages, rating_count) FROM stdin;
book_1777065316.063593	AI	\N	cat_programming		0.0	2026	1	https://firebasestorage.googleapis.com/v0/b/libraryapp-c781e.firebasestorage.app/o/books%2F1777065303276-epnv8jukvgs-CRD_EF4DQ8QH_baked.png?alt=media&token=21f5647e-ee74-423b-95ed-7eca96c4315c	English	450	0
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (id, name, image_url) FROM stdin;
cat_uncategorized	Uncategorized	\N
cat_programming	Programming	\N
\.


--
-- Data for Name: fine_payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fine_payments (id, fine_id, member_id, payment_date, payment_amount, payment_method, handled_by, notes, created_at) FROM stdin;
\.


--
-- Data for Name: fines; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fines (id, member_id, loan_id, fine_date, fine_amount, status, reason, due_date, paid_at, payment_method, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: interactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.interactions (id, user_id, book_id, interaction_type, created_at) FROM stdin;
\.


--
-- Data for Name: loans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.loans (id, book_id, member_id, loan_date, returned_date) FROM stdin;
\.


--
-- Data for Name: reservations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reservations (id, book_id, member_id, reservation_date, status) FROM stdin;
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.settings (id, loan_period_days, max_books_per_user, grace_period_days, daily_fine_rate, max_fine_cap, block_on_unpaid_fines, fine_threshold, send_notifications, notification_days_before_due, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, member_id, name, email, password, phone, address, profile_image, joined_date, created_at, updated_at) FROM stdin;
db27835e-9f3e-4a5d-bb6c-b12edbd4aea6	db27835e-9f3e-4a5d-bb6c-b12edbd4aea6	Anusan Krishnathas	krishnaanu200302@gmail.com	\N	\N	\N	\N	2026-04-24	2026-04-24 21:13:15.684578	2026-04-24 21:13:15.684591
81d86eea-e7c7-484e-ae2c-bbb453452616	81d86eea-e7c7-484e-ae2c-bbb453452616		\N	\N	\N	\N	\N	2026-04-25	2026-04-25 09:38:46.441768	2026-04-25 09:38:46.441777
67e9309a-9917-4776-b8b2-3f8e8c972b61	67e9309a-9917-4776-b8b2-3f8e8c972b61		\N	\N	\N	\N	\N	2026-04-25	2026-04-25 09:40:15.486183	2026-04-25 09:40:15.48619
\.


--
-- Name: interactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.interactions_id_seq', 1, false);


--
-- Name: authors authors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (id);


--
-- Name: books books_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: fine_payments fine_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fine_payments
    ADD CONSTRAINT fine_payments_pkey PRIMARY KEY (id);


--
-- Name: fines fines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fines
    ADD CONSTRAINT fines_pkey PRIMARY KEY (id);


--
-- Name: interactions interactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_pkey PRIMARY KEY (id);


--
-- Name: loans loans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (id);


--
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: books books_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.authors(id);


--
-- Name: books books_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: fine_payments fine_payments_fine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fine_payments
    ADD CONSTRAINT fine_payments_fine_id_fkey FOREIGN KEY (fine_id) REFERENCES public.fines(id);


--
-- Name: fine_payments fine_payments_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fine_payments
    ADD CONSTRAINT fine_payments_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.users(id);


--
-- Name: fines fines_loan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fines
    ADD CONSTRAINT fines_loan_id_fkey FOREIGN KEY (loan_id) REFERENCES public.loans(id);


--
-- Name: fines fines_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fines
    ADD CONSTRAINT fines_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.users(id);


--
-- Name: interactions interactions_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(id);


--
-- Name: interactions interactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interactions
    ADD CONSTRAINT interactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: loans loans_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(id);


--
-- Name: loans loans_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.users(id);


--
-- Name: reservations reservations_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(id);


--
-- Name: reservations reservations_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.users(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO cloudsqlsuperuser;


--
-- PostgreSQL database dump complete
--

\unrestrict fdhJl2hibvIDMWbS92dPcIVsIA2ddfld4seS0xLL7EWMIxHWUJvsqKSOqhVG1Ax

