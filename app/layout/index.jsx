import React from 'react';
import classnames from 'classnames';
import AdminOnly from '../components/admin-only';
import SiteNav from './site-nav';
import SiteFooter from './site-footer';

import style from './index.styl';
void style;

const LAYOUT_DEV_MODE = process.env.NODE_ENV !== 'production' &&
  typeof window !== 'undefined' &&
  location.search.indexOf('layout-dev') !== -1;

const AppLayout = React.createClass({
  propTypes: {
    user: React.PropTypes.any,
    children: React.PropTypes.node,
  },

  childContextTypes: {
    setAppHeaderVariant: React.PropTypes.func,
  },

  getInitialState() {
    return {
      siteHeaderDemoted: false,
      siteHeaderRevealed: false,
      mainContentScale: 1,
      headerHeight: 0,
    };
  },

  getChildContext() {
    return {
      setAppHeaderVariant: (variant) => {
        this.setState({
          siteHeaderDemoted: variant === 'demoted',
        });
      },
    };
  },

  componentDidMount() {
    addEventListener('locationchange', this.handleNavigation);
  },

  componentWillUnmount() {
    removeEventListener('locationchange', this.handleNavigation);
  },

  handleNavigation() {
    this.setState({
      siteHeaderRevealed: false,
    });
  },

  matchWindowScale() {
    const wholeWidth = this.refs.container.offsetWidth;
    const containerStyle = getComputedStyle(this.refs.container);
    const insetEachSide = 2 * parseFloat(containerStyle.fontSize);
    const scaledWidth = wholeWidth - (insetEachSide * 2);
    const mainContentScale = scaledWidth / wholeWidth;
    const headerHeight = this.refs.header.offsetHeight;
    this.setState({ mainContentScale, headerHeight });
  },

  togglePrimaryNav() {
    this.matchWindowScale();
    this.setState({
      siteHeaderRevealed: !this.state.siteHeaderRevealed,
    });
  },

  toggleState(event) {
    this.setState({
      [event.target.name]: event.target.checked,
    });
  },

  render() {
    let togglePrimaryNav;
    if (this.state.siteHeaderDemoted) {
      togglePrimaryNav = this.togglePrimaryNav;
    }

    const demotedHeaderIsRevealed = this.state.siteHeaderDemoted && this.state.siteHeaderRevealed;

    return (
      <div
        ref="container"
        className={classnames('app-layout', {
          'app-layout--site-header-demoted': this.state.siteHeaderDemoted,
        })}
      >
        <AdminOnly whenActive>
          <div className="app-layout__admin-indicator" title="Admin mode on!"></div>
        </AdminOnly>

        <header
          ref="header"
          className={classnames('app-layout__header', {
            'app-layout__header--demoted': this.state.siteHeaderDemoted,
          })}
          user={this.props.user}
        >
          <SiteNav ref="mainNav" user={this.props.user} onToggle={togglePrimaryNav} />
        </header>

        <div className="app-layout__not-header">
          <div
            className={classnames('app-layout__main', {
              'app-layout__main--promoted': this.state.siteHeaderDemoted,
              'app-layout__main--set-aside': demotedHeaderIsRevealed,
            })}
            style={demotedHeaderIsRevealed ? {
              transform: `
                translateY(${this.state.headerHeight}px)
                scale(${this.state.mainContentScale})
              `,
            } : null}
          >
            {this.props.children}
            <div
              className={classnames('app-layout__main-overlay', {
                'app-layout__main-overlay--active': demotedHeaderIsRevealed,
              })}
              style={{
                display: demotedHeaderIsRevealed ? 'block' : 'none',
              }}
              onClick={this.togglePrimaryNav}
            ></div>
          </div>

          <footer className="app-layout__footer">
            <SiteFooter user={this.props.user} />

            {LAYOUT_DEV_MODE &&
              <div
                style={{
                  background: 'yellow',
                  bottom: 0,
                  color: 'black',
                  fontSize: '10px',
                  fontWeight: 'bold',
                  left: 0,
                  padding: '0 0.5em',
                  position: 'fixed',
                }}
              >
                <label>
                  <input
                    type="checkbox"
                    name="siteHeaderDemoted"
                    checked={this.state.siteHeaderDemoted}
                    onChange={this.toggleState}
                  />{' '}
                  Primary header demoted
                </label>
                <br />
              </div>}
          </footer>
        </div>
      </div>
    );
  },
});

export default AppLayout;
