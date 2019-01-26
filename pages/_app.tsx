import fetch from 'isomorphic-unfetch';
import App, { Container, NextAppContext } from 'next/app';
import NextError from 'next/error';
import React from 'react';
import { defineMessages, IntlProvider } from 'react-intl';
import { graphql } from 'react-relay';
import {
  Environment,
  // @ts-ignore Missing type.
  fetchQuery,
  Network,
  RecordMap,
  RecordSource,
  Store,
} from 'relay-runtime';
import IntlProviderFix from '../components/IntlProviderFix';
import RelayProviderFix from '../components/RelayProviderFix';
import ViewerTheme from '../components/ViewerTheme';
import AppContext from '../contexts/AppContext';
import { AppQuery } from '../generated/AppQuery.graphql';
import { AuthSyncProvider, maybeGetAuthToken } from '../hooks/useAuth';

export type AppHref =
  | '/'
  | 'https://twitter.com/steida'
  | '/me'
  | {
      pathname: '/signin';
      query?: { redirectUrl: string };
    }
  | {
      pathname: '/web';
      query: { id: string };
    };

// Page titles can not be collocated within pages because that would defeat
// code splitting. One nav component would import many whole pages.
export const pageTitles = defineMessages({
  index: {
    defaultMessage: 'Este',
    id: 'pageTitles.index',
  },
  me: {
    defaultMessage: 'Me',
    id: 'pageTitles.me',
  },
  signIn: {
    defaultMessage: 'Sign in',
    id: 'pageTitles.signIn',
  },
});

const createRelayEnvironment = (
  apiEndpoint: string,
  token: string,
  records: RecordMap,
  rejectErrors: boolean,
) => {
  return new Environment({
    network: Network.create(async (operation, variables) => {
      const response = await fetch(apiEndpoint, {
        body: JSON.stringify({ query: operation.text, variables }),
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { authorization: `Bearer ${token}` } : null),
        },
        method: 'POST',
      });
      // Relay fetch ignores json.errors, so we have to handle it manually.
      // But only for queries. Mutations are ok.
      const json = await response.json();
      if (rejectErrors && json.errors) return Promise.reject(json.errors);
      return json;
    }),
    store: new Store(new RecordSource(records)),
  });
};

const appQuery = graphql`
  query AppQuery(
    $id: ID!
    $isIndexPage: Boolean!
    $isMePage: Boolean!
    $isSignInPage: Boolean!
    $isWebPage: Boolean!
  ) {
    ...ViewerThemeQuery
    ...pagesQuery @include(if: $isIndexPage)
    ...meQuery @include(if: $isMePage)
    ...signinQuery @include(if: $isSignInPage)
    ...webQuery @include(if: $isWebPage) @arguments(id: $id)
  }
`;

let host = '';

const getApiEndpoint = (host: string): string => {
  const hasNoPortSoIsProbablyDeployed = host.indexOf(':') === -1;
  if (hasNoPortSoIsProbablyDeployed) return `https://${host}/api`;
  return `http://${host.replace('3000', '4000')}`;
};

interface MyAppProps {
  host: string;
  initialNow: number;
  pageProps: { data: AppQuery['response'] | null };
  relayRecords: RecordMap;
  statusCode: number | undefined;
  token: string;
  variables: AppQuery['variables'];
}

export default class MyApp extends App<MyAppProps> {
  static async getInitialProps({
    router,
    ctx,
  }: NextAppContext): Promise<MyAppProps> {
    // Types require fully defined URL query. Will not be used entirely ofc.
    const defaultQueryArgs = {
      id: '',
    };
    const isPageQueryArgs = {
      isIndexPage: '/' === ctx.pathname,
      isMePage: '/me' === ctx.pathname,
      isSignInPage: '/signin' === ctx.pathname,
      isWebPage: '/web' === ctx.pathname,
    };

    host = host || (ctx.req && ctx.req.headers.host) || '';

    const props = {
      host,
      initialNow: Date.now(),
      pageProps: { data: null },
      relayRecords: {},
      statusCode: ctx.res && ctx.res.statusCode,
      token: maybeGetAuthToken(ctx.req),
      variables: {
        ...defaultQueryArgs,
        ...ctx.query,
        ...isPageQueryArgs,
      },
    };

    if (props.statusCode != null && props.statusCode >= 400) {
      return props;
    }

    const relayEnvironment = createRelayEnvironment(
      getApiEndpoint(host),
      props.token,
      {},
      true,
    );
    try {
      props.pageProps.data = await fetchQuery(
        relayEnvironment,
        appQuery,
        props.variables,
      );
    } catch (errors) {
      const knownGraphQLErrors = Array.isArray(errors)
        ? errors
            .map(error => error && error.extensions && error.extensions.code)
            .filter(
              code =>
                code === 'FORBIDDEN' ||
                code === 'NOTFOUND' ||
                code === 'UNAUTHENTICATED',
            )
            .map(code =>
              code === 'FORBIDDEN'
                ? 403
                : code === 'UNAUTHENTICATED'
                ? 401
                : 404,
            )
        : null;

      if (knownGraphQLErrors && knownGraphQLErrors.length > 0) {
        // The order is important.
        if (knownGraphQLErrors.includes(401)) {
          props.statusCode = 401;
        } else if (knownGraphQLErrors.includes(404)) {
          props.statusCode = 404;
        } else {
          props.statusCode = 403;
        }
      } else {
        props.statusCode = 500;
        // tslint:disable-next-line:no-console
        console.log(errors);
      }

      if (ctx.res) ctx.res.statusCode = props.statusCode;
    }

    props.relayRecords = relayEnvironment
      .getStore()
      .getSource()
      .toJSON();

    if (props.statusCode === 401) {
      const signInHref: AppHref = {
        pathname: '/signin',
        query: { redirectUrl: ctx.asPath },
      };
      if (ctx.res) {
        const Location = `${
          signInHref.pathname
        }?redirectUrl=${encodeURIComponent(ctx.asPath)}`;
        ctx.res.writeHead(302, { Location });
        ctx.res.end();
      } else {
        router.replace(signInHref);
      }
    }

    return props;
  }

  render() {
    const {
      Component: Page,
      initialNow,
      pageProps,
      relayRecords,
      statusCode,
      token,
      variables,
    } = this.props;

    host = host || this.props.host;

    // TODO: Add custom 404 and 500 pages.
    if (statusCode != null && statusCode >= 400)
      return <NextError statusCode={statusCode} />;

    const relayEnvironment = createRelayEnvironment(
      getApiEndpoint(host),
      token,
      relayRecords,
      false,
    );

    return (
      <Container>
        <RelayProviderFix environment={relayEnvironment} variables={variables}>
          <IntlProvider
            locale="en"
            initialNow={initialNow}
            textComponent={React.Fragment}
          >
            <ViewerTheme data={pageProps.data}>
              {theme => {
                return (
                  <IntlProviderFix>
                    {intl => (
                      <AppContext.Provider
                        value={{ intl, relayEnvironment, theme }}
                      >
                        <AuthSyncProvider>
                          <Page {...pageProps} />
                        </AuthSyncProvider>
                      </AppContext.Provider>
                    )}
                  </IntlProviderFix>
                );
              }}
            </ViewerTheme>
          </IntlProvider>
        </RelayProviderFix>
      </Container>
    );
  }
}
