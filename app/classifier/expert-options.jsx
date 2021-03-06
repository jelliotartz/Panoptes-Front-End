import React from 'react';
import TriggeredModalForm from 'modal-form/triggered';
import isAdmin from '../lib/is-admin';

function ExpertOptions(props) {
  function handleGoldStandardChange(e) {
    props.classification.update({ gold_standard: e.target.checked || undefined });
  }

  function handleDemoModeChange(e) {
    props.onChangeDemoMode(e.target.checked);
  }

  return (
    <TriggeredModalForm
      trigger={<i className="fa fa-cog fa-fw" />}
    >
      {(props.userRoles.includes('owner') || props.userRoles.includes('expert')) &&
        <p>
          <label>
            <input type="checkbox" checked={!!props.classification.gold_standard} onChange={handleGoldStandardChange} />{' '}
            Gold standard mode
          </label>{' '}
          <TriggeredModalForm
            trigger={<i className="fa fa-question-circle" />}
          >
            <p>A “gold standard” classification is one that is known to be completely accurate. We’ll compare other classifications against it during aggregation.</p>
          </TriggeredModalForm>
        </p>
      }

      {(isAdmin() || props.userRoles.includes('owner') || props.userRoles.includes('collaborator')) &&
        <p>
          <label>
            <input type="checkbox" checked={props.demoMode} onChange={handleDemoModeChange} />{' '}
            Demo mode
          </label>{' '}
          <TriggeredModalForm
            trigger={<i className="fa fa-question-circle" />}
          >
            <p>In demo mode, classifications <strong>will not be saved</strong>. Use this for quick, inaccurate demos of the classification interface.</p>
          </TriggeredModalForm>
        </p>
      }
    </TriggeredModalForm>
  );
}

ExpertOptions.propTypes = {
  classification: React.PropTypes.shape({
    update: React.PropTypes.func,
    gold_standard: React.PropTypes.bool
  }),
  demoMode: React.PropTypes.bool,
  onChangeDemoMode: React.PropTypes.func,
  userRoles: React.PropTypes.arrayOf(React.PropTypes.string)
};

export default ExpertOptions;
